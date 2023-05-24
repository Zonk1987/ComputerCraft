-- Config
local sortOpt = "Job" -- Set the desired sorting option (e.g.: "Job", "Name", "ID")
local pageSize = 40 -- Set the number of citizens to display per page


-- API's
os.loadAPI("bigfont")
os.loadAPI("button.lua")

-- Checks if a peripheral with the specified name exists and returns it.
-- Throws an error if the peripheral is not found.
local function checkPeripheral(name, errorMessage)
    local peripheral = peripheral.find(name)
    assert(peripheral, errorMessage)
    return peripheral
end

-- Check if "colonyIntegrator" peripheral exists and assign it to "colony"
local colony = checkPeripheral("colonyIntegrator", "Colony Integrator not found.")
assert(colony.isInColony, "Colony Integrator is not in a colony.")
print("Colony Integrator initialized.")

-- Check if "monitor" peripheral exists and assign it to "mon"
local mon = checkPeripheral("monitor", "Monitor not found.")
print("Monitor initialized.")

button.setMonitor(mon)

-- Sorts a table based on the specified sorting option.
local function SortTable(a, b)
    if sortOpt == "Job" then
        local aJob = a.work and a.work.type
        local bJob = b.work and b.work.type
        if aJob and bJob then
            return aJob < bJob
        else
            -- Handle nil values by considering them as greater than non-nil values
            return aJob ~= nil
        end
    elseif sortOpt == "Name" then
        return a.name < b.name
    elseif sortOpt == "ID" then
        return (a.id or 0) < (b.id or 0)
    end
end

-- Converts the first character of a string to uppercase.
local function firstToUpper(str)
    return (str or ""):gsub("^%l", string.upper)
end

-- Formats a given number by padding it with leading spaces to a width of 3 characters.
local function FormatNumber(number)
    local formattedNumber = string.format("%3d", number)
    return formattedNumber
end

-- Fills a cell with equal (=) characters of the specified width.
local function fillCellWithEquals(width)
    local equals = string.rep("=", width)
    return equals
end

-- Draw a filled box with a large header
local function drawFilledBoxWithHeader(x, y, width, height, color, headerText)
    -- Set the desired color as the background color
    mon.setBackgroundColor(color)

    -- Calculate the position and size of the header
    local headerHeight = 0
    local headerX = x + math.floor((width - #headerText) / 2)
    local headerY = y + math.floor((height - headerHeight) / 2)

    -- Calculate the position of the filled box
    local boxX = x
    local boxY = y + headerHeight
    local boxWidth = width
    local boxHeight = height - headerHeight

    -- Draw the filled box
    for i = 0, boxHeight - 1 do
        mon.setCursorPos(boxX, boxY + i)
        mon.write(string.rep(" ", boxWidth))
    end

    -- Set the color for the header
    mon.setTextColor(colors.white)
    mon.setBackgroundColor(color)

    -- Draw the header
    bigfont.writeOn(mon,1,headerText,25, 2)
end

-- Retrieves the first name from a full name.
local function FirstName(name)
    local firstName = string.match(name, "([^%s]+)")
    return firstName or ""
end

-- Retrieves happiness data for a citizen.
local function GetHappiness(happiness)
    local formattedHappiness = string.format("%4.1f", happiness)
    local textColor = colors.pink

    if happiness == 10.0 then
        textColor = colors.green
    end

    return {
        value = formattedHappiness,
        color = textColor
    }
end

-- Retrieves the job status data for a citizen.
local function GetJobStatus(status)
    local jobStatusText = {
        Working = { text = "Working", color = colors.green }
    }
    return jobStatusText[status] or { text = status, color = colors.red }
end

-- Retrieves the color associated with a specific job.
local function SetJobColor(job)
    local jobColors = {
        Knight = colors.magenta,
        deliveryman = colors.yellow,
        Archer = colors.pink,
        builder = colors.brown,
        Druid = colors.lime,
        enchanter = colors.purple,
        farmer = colors.cyan,
        school = colors.orange,
        university = colors.lightBlue
    }
    return jobColors[job] or colors.blue
end

-- Calculates the distance between a bed and a work location.
local function GetBedDistance(bed, work)
    if bed == nil or work == nil then
        return ""
    end

    local bedY, bedX = bed.z, bed.x
    local workY, workX = work.z, work.x
    local distanceY = math.abs(workY - bedY)
    local distanceX = math.abs(workX - bedX)
    local distance = math.sqrt(distanceX ^ 2 + distanceY ^ 2)
    local formattedDistance = string.format("%4.1f", distance)

    local textColor = colors.green
    if distance > 99 then
        textColor = colors.red
    elseif distance > 75 then
        textColor = colors.orange
    elseif distance > 50 then
        textColor = colors.yellow
    end

    return {
        value = formattedDistance,
        color = textColor
    }
end

-- Compares two tables of citizens and returns true if they are equal, false otherwise.
local function compareCitizens(citizens1, citizens2)
    if #citizens1 ~= #citizens2 then
        return false
    end

    for i, citizen1 in ipairs(citizens1) do
        local citizen2 = citizens2[i]

        if not citizen1 or not citizen2 or
           citizen1.id ~= citizen2.id or
           citizen1.name ~= citizen2.name or
           not citizen1.location or not citizen2.location or
           citizen1.location.x ~= citizen2.location.x or
           citizen1.location.y ~= citizen2.location.y or
           citizen1.location.z ~= citizen2.location.z or
           (citizen1.work and citizen1.work.type) ~= (citizen2.work and citizen2.work.type) or
           citizen1.state ~= citizen2.state or
           citizen1.happiness ~= citizen2.happiness or
           (citizen1.home and citizen1.home.location) ~= (citizen2.home and citizen2.home.location) or
           (citizen1.work and citizen1.work.location) ~= (citizen2.work and citizen2.work.location) then
           return false
        end
    end

    return true
end

-- Define the table headings as a constant variable
local headings = {
    {name = "ID",                   width = 4,      alignment = "center",   color = colors.white},
    {name = "Name",                 width = 11,     alignment = "left",     color = colors.white},
    {name = "Location (X, Y, Z)",   width = 19,     alignment = "center",   color = colors.white},
    {name = "Job",                  width = 15,     alignment = "left",     color = colors.white},
    {name = "Status",               width = 19,     alignment = "center",   color = colors.white},
    {name = "Happiness",            width = 10,     alignment = "center",   color = colors.white},
    {name = "Commute",              width = 10,     alignment = "center",   color = colors.white}
}

local formattedHeadings = {} -- Format the table headings
local sortedCitizens = {} -- Add a new variable to store the sorted citizens
sortedCitizens = colony.getCitizens() or {} -- Initialize the sortedCitizens variable with an empty table
local totalWidth = 0

local totalPages = math.ceil(#sortedCitizens / pageSize)

for _, heading in ipairs(headings) do
    local formattedHeading = string.sub(heading.name, 1, heading.width)
    totalWidth = totalWidth + heading.width
    table.insert(formattedHeadings, formattedHeading)
end

-- Calculate the total width of the table
totalWidth = totalWidth + #headings - 1  -- Account for the separators '|'

local offset = 22

-- Displays a table of citizens on the monitor.
local function ShowCitizens(page)
    local counter = 1
    local screenHeight, screenWidth = mon.getSize()
    local row = 7
    local column = math.floor(screenWidth / 2) - offset

    -- Verifying the page number is within the valid range
    page = math.max(page, 1)
    page = math.min(page, totalPages)

    -- Retrieve the newCitizens data
    local citizens = colony.getCitizens() or {}

    -- Only update the sortedCitizens if the data changes
    if #citizens ~= #sortedCitizens or not compareCitizens(citizens, sortedCitizens) then
        sortedCitizens = citizens
        table.sort(sortedCitizens, SortTable)
    end

    local numHeadings = #headings
    
    -- Clear the monitor
    mon.setTextScale(0.5)
    mon.clear()

    -- Write the table headings to the monitor
    for i, heading in ipairs(headings) do
        mon.setTextColor(heading.color)
        local headingText = string.sub(heading.name, 1, heading.width, heading.color)
        local headingLength = #headingText

        -- Write the separator line between columns
        if i < numHeadings then
            mon.setCursorPos(column + heading.width, row)
            mon.write("|")
        end
        
        -- Write the second line with equals sign
        mon.setCursorPos(math.floor(screenWidth / 2) - offset, row + 1)
        mon.write(fillCellWithEquals(totalWidth)) 

        if heading.alignment == "left" then
            mon.setCursorPos(column, row)
            mon.write(headingText)
        elseif heading.alignment == "center" then
            local headingPadding = math.floor((heading.width - headingLength) / 2)
            local headingLeftPadding = headingPadding
            local headingRightPadding = heading.width - headingLength - headingPadding

            mon.setCursorPos(column + headingLeftPadding, row)
            mon.write(headingText)
            mon.setCursorPos(column + headingLeftPadding + headingLength + headingRightPadding, row)
        elseif heading.alignment == "right" then
            local headingPadding = heading.width - headingLength

            mon.setCursorPos(column + headingPadding, row)
            mon.write(headingText)
        end

        column = column + heading.width + 1
    end

    

    row = row + 2
    column = math.floor(screenWidth / 2) - offset

    -- Write the citizen data to the monitor
    local startIdx = (page - 1) * pageSize + 1
    local endIdx = math.min(startIdx + pageSize - 1, #sortedCitizens)

    for i = startIdx, endIdx do
        local citizen = sortedCitizens[i]
        -- Get Data to opperate with
        if citizen then
            local id = citizen.id
            local displayName = citizen.name
            local locationX = FormatNumber(citizen.location.x)
            local locationY = FormatNumber(citizen.location.y)
            local locationZ = FormatNumber(citizen.location.z)
            local job = citizen.work and citizen.work.type or nil
            local jobStatus = citizen.state
            local happiness = citizen.happiness
            local bedLocation = citizen.home and citizen.home.location or nil
            local workLocation = citizen.work and citizen.work.location or nil

            -- Write the citizen data to the monitor
            for i, heading in ipairs(headings) do
                local content = ""
                local contentAlignment = "left"
                local contentColor = nil

                if heading.name == "ID" then
                    content = FormatNumber(id)
                    contentAlignment = "center"
                    contentColor = colors.white
                elseif heading.name == "Name" then
                    content = FirstName(displayName)
                    contentAlignment = "left"
                    contentColor = colors.blue
                elseif heading.name == "Location (X, Y, Z)" then
                    content = "(" .. locationX .. "," .. locationY .. "," .. locationZ .. ")"
                    contentAlignment = "center"
                    contentColor = colors.white
                elseif heading.name == "Job" then
                    content = firstToUpper(job or "")
                    contentAlignment = "left"
                    contentColor = SetJobColor(job)
                elseif heading.name == "Status" then
                    local statusData = GetJobStatus(jobStatus)
                    content = statusData.text
                    contentColor = statusData.color
                    contentAlignment = "center"
                elseif heading.name == "Happiness" then
                    local happinessData = GetHappiness(happiness)
                    content = happinessData.value
                    contentColor = happinessData.color
                    contentAlignment = "center"
                elseif heading.name == "Commute" then
                    local distanceData = GetBedDistance(bedLocation, workLocation)
                    content = distanceData.value
                    contentColor = distanceData.color
                    contentAlignment = "center"
                end

                -- Set the cursor position based on alignment
                local contentLength = content and string.len(content) or 0
                local contentPadding = heading.width - contentLength

                if contentAlignment == "left" then
                    mon.setCursorPos(column, row)
                elseif contentAlignment == "center" then
                    local contentLeftPadding = math.floor(contentPadding / 2)
                    local contentRightPadding = contentPadding - contentLeftPadding
                    mon.setCursorPos(column + contentLeftPadding, row)
                elseif contentAlignment == "right" then
                    mon.setCursorPos(column + contentPadding, row)
                end

                -- Set content color
                if contentColor then
                    mon.setTextColor(contentColor)
                end

                -- Write the content
                mon.write(content)

                -- Write the separator line between columns '|'
                if i < numHeadings then
                    mon.setCursorPos(column + heading.width, row)
                    mon.setTextColor(heading.color)
                    mon.write("|")
                end

                column = column + heading.width + 1
            end
        end
        row = row + 1
        counter = counter + 1
        column = math.floor(screenWidth / 2) - offset
    end
    local screenWidth, screenHeight = mon.getSize()
    mon.setCursorPos(screenWidth - 8, screenHeight)
    mon.setTextColor(colors.white)
    mon.write("[Page " .. string.format("%2d", page) .. "]")
end

local currentPage = 1

-- Create previous and next buttons
local next = button.create().setText(">").setPos(96, 1).setAlign("center").setSize(5, 5)
local prev = button.create().setText("<").setPos(1, 1).setAlign("center").setSize(5, 5)

-- Create previous and next buttons
next.onClick(function() currentPage = currentPage + 1 ShowCitizens(currentPage) end)
prev.onClick(function() currentPage = currentPage - 1 ShowCitizens(currentPage) end)


-- Continuously displays the citizens table on the monitor.
local function main()
    ShowCitizens(currentPage)
    drawFilledBoxWithHeader(1, 1, mon.getSize(), 5, colors.lightGray, "Citizen Statistic")
    mon.setBackgroundColor(colors.black)
    button.await(next, prev)

    if currentPage < 1 then
        currentPage = 1
    elseif currentPage > totalPages then
        currentPage = totalPages
    end
end

local function wait()
    sleep(1)
end

while true do
    parallel.waitForAny(main,wait)
end
