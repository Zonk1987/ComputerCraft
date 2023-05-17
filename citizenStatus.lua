-- Config
local sortOpt = "ID" -- Set the desired sorting option (e.g., "Job", "Name", "ID")

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


-- Sorts a table based on the specified sorting option.
function SortTable(a, b)
    if sortOpt == "Job" then
        local aJob = a.work and a.work.type
        local bJob = b.work and b.work.type
        return aJob and bJob and aJob < bJob
    elseif sortOpt == "Name" then
        return a.name and b.name and a.name < b.name
    elseif sortOpt == "ID" then
        return (a.id or 0) < (b.id or 0)
    end
end

-- Converts the first character of a string to uppercase.
function firstToUpper(str)
    return (str or ""):gsub("^%l", string.upper)
end

-- Converts a decimal number to a normal number by formatting it with leading spaces to a width of 2 characters.
function decimal_to_normal(num)
    local formattedNum = string.format("%2d", num or "")
    return formattedNum
end

-- Formats a given number by padding it with leading spaces to a width of 3 characters.
function FormatNumber(number)
    local formattedNumber = string.format("%3d", number)
    return formattedNumber
end

-- Fills a cell with equal (=) characters of the specified width.
function FillCellWithEquals(width)
    local equals = string.rep("=", width)
    return equals
end

-- Retrieves the first name from a full name.
function FirstName(name)
    local firstName = string.match(name, "([^%s]+)")
    return firstName or ""
end

-- Retrieves happiness data for a citizen.
function GetHappiness(happiness)
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
function GetJobStatus(status)
    local statusText = {
        ["Working"] = {text = "Working", color = colors.green}
    }

    return statusText[status] or {text = status, color = colors.red}
end

-- Retrieves the color associated with a specific job.
function SetJobColor(job)
    local jobColors = {
        ["Knight"] = colors.magenta,
        ["deliveryman"] = colors.yellow,
        ["Archer"] = colors.pink, 
        ["builder"] = colors.brown,
        ["Druid"] = colors.lime,
        ["enchanter"] = colors.purple,
        ["farmer"] = colors.cyan,
        ["school"] = colors.orange,
        ["university"] = colors.lightBlue
    }
    
    return jobColors[job] or colors.blue
end

-- Calculates the distance between a bed and a work location.
function GetBedDistance(bed, work)
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

-- Displays a table of citizens on the monitor.
function ShowCitizens()
    local counter = 1
    local row = 5
    local column = 1
    local citizens = colony.getCitizens()
    table.sort(citizens, SortTable)  -- Compare and sort elements in a table using the SortTable function
    mon.setTextScale(0.5)

    -- Define the table headings
    local headings = {
        {name = "ID", width = 4, alignment = "center", color = colors.white},
        {name = "Name", width = 10, alignment = "left", color = colors.white},
        {name = "Location (X, Y, Z)", width = 19, alignment = "center", color = colors.white},
        {name = "Job", width = 15, alignment = "left", color = colors.white},
        {name = "Status", width = 19, alignment = "center", color = colors.white},
        {name = "Happiness", width = 10, alignment = "center", color = colors.white},
        {name = "Commute", width = 10, alignment = "center", color = colors.white}
    }

    -- Clear the monitor
    mon.clear()

    -- Write the table headings to the monitor
    for i, heading in ipairs(headings) do
        mon.setTextColor(heading.color)
        local headingText = string.sub(heading.name, 1, heading.width, heading.color)
        local headingLength = #headingText

        -- Calculate the total width of the table
        local totalWidth = 0
        for _, heading in ipairs(headings) do
            totalWidth = totalWidth + heading.width
        end
        totalWidth = totalWidth + #headings - 1  -- Account for the separators '|'

        -- Write the separator line between columns
        if i < #headings then
            mon.setCursorPos(column + heading.width, row)
            mon.write("|")
        end
        
        -- Write the second line with equals sign
        mon.setCursorPos(1, row + 1)
        mon.write(FillCellWithEquals(totalWidth)) 

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
    column = 1

    for _, citizen in ipairs(citizens) do
        -- Get Data to opperate with
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

            if heading.name == "ID" then
                content = decimal_to_normal(id)
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

            -- Write the separator line between columns
            if i < #headings then
                mon.setCursorPos(column + heading.width, row)
                mon.setTextColor(heading.color)
                mon.write("|")
            end

            column = column + heading.width + 1
        end

        row = row + 1
        counter = counter + 1
        column = 1
    end
end

-- Continuously displays the citizens table on the monitor.
while true do
    ShowCitizens()
    sleep(1)
end
