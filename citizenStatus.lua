-- Config
local sortOpt = "ID" -- There are options to sort the Table by "Job; Name; ID"

-- Startup Stuff
local colony = peripheral.find("colonyIntegrator")
if not colony then
    error("Colony Integrator not found.")
end
if not colony.isInColony then
    error("Colony Integrator is not in a colony.")
end
print("Colony Integrator initialized.")

local mon = peripheral.find("monitor")
if not mon then
    error("Monitor not found.")
end
print("Monitor initialized.")
-- End Startup Stuff

function SortTable(a, b)
    if sortOpt == "Job" then
        local aJob = a["work"] and a["work"]["type"] or nil
        local bJob = b["work"] and b["work"]["type"] or nil
        if (a == nil or aJob == nil) then
            return false
        end
        if (b == nil or bJob == nil) then
            return false
        end
        return aJob < bJob
    elseif sortOpt == "Name" then
        local aName = a["name"]
        local bN = b["name"]
        if aName == nil then
            return false
        end
        if bN == nil then
            return false
        end
        return aName < bN
    elseif sortOpt == "ID" then
        local aID = a["id"] or 0
        local bID = b["id"] or 0
        return aID < bID
    end
end

local function firstToUpper(str)
    if str == nil then
        return ""
    else
        return (str:gsub("^%l", string.upper))
    end
end

local function decimal_to_normal(num)
    if num == nil then
        return ""
    else
        local formattedNum = string.format("%2d", num)
        if num < 10 then
            formattedNum = " " .. formattedNum
        end
        return formattedNum
    end
end

function FormatNumber(number)
    local formattedNumber = string.format("%d", number)

    if number < 10 then
        formattedNumber = "  " .. formattedNumber
    elseif number < 100 then
        formattedNumber = " " .. formattedNumber
    end

    return formattedNumber
end

function FirstName(name)
    local returnStr = ""
    for i = 1, #name do
        local char = string.sub(name, i, i)
        if (char == " " or i == 9) then
            return returnStr
        end
        returnStr = returnStr .. char
    end
    return returnStr
end

function GetHappiness(happiness)
    local mult = 10 -- # of places
    happiness = math.floor(happiness * mult + 0.5) / mult
    local textColor = colors.pink

    if happiness == 10.0 then
        textColor = colors.green
    end

    local formattedHappiness = string.format("%.1f", happiness)
    if happiness < 10 then
        formattedHappiness = " " .. formattedHappiness
    end

    return {
        value = formattedHappiness,
        color = textColor
    }
end

function GetJobStatus(status)
    local statusText = {
        ["Working"] = {
            text = "Working",
            color = colors.green
        },
        ["Farming"] = {
            text = "Working",
            color = colors.green
        },
        ["Delivering"] = {
            text = "Working",
            color = colors.green
        },
        ["Mining"] = {
            text = "Working",
            color = colors.green
        },
        ["Composting"] = {
            text = "Working",
            color = colors.green
        },
        ["Searching for trees"] = {
            text = "Working",
            color = colors.green
        }
    }

    if statusText[status] == nil then
        return {
            text = status,
            color = colors.red
        }
    else
        return statusText[status]
    end
end

function SetJobColor(job)
    local jobColors = {
        ["Knight"] = colors.magenta, -- does not work atm
        ["deliveryman"] = colors.yellow,
        ["Archer"] = colors.pink, -- does not work atm
        ["builder"] = colors.brown,
        ["Druid"] = colors.lime, -- does not work atm
        ["enchanter"] = colors.purple,
        ["farmer"] = colors.cyan,
        ["school"] = colors.orange,
        ["university"] = colors.lightBlue
    }
    if (jobColors[job] == nil) then
        return colors.blue
    else
        return jobColors[job]
    end
end

function GetBedDistance(bed, work)
    if bed == nil or work == nil then
        return ""
    else
        local bedY = bed["z"]
        local bedX = bed["x"]
        local workY = work["z"]
        local workX = work["x"]
        local distanceY = math.abs(workY - bedY)
        local distanceX = math.abs(workX - bedX)
        local distance = math.sqrt(distanceX ^ 2 + distanceY ^ 2)
        local formattedDistance = string.format("%4.1f", distance)

        local textColor = colors.green
        if distance > 99 then
            textColor = colors.red
        elseif distance > 75 and distance < 100 then
            textColor = colors.orange
        elseif distance > 50 and distance < 76 then
            textColor = colors.yellow
        end

        return {
            value = formattedDistance,
            color = textColor
        }
    end
end

function ShowCitizens()
    local counter = 1
    local row = 1
    local column = 1
    local citizens = colony.getCitizens()
    table.sort(citizens, SortTable)
    mon.setTextScale(0.5)

    -- Define the table headings
    local headings = {{
        name = "ID",
        width = 4,
        alignment = "center",
        color = colors.white
    }, {
        name = "|",
        width = 1,
        alignment = "center",
        color = colors.white
    }, {
        name = "Name",
        width = 10,
        alignment = "left",
        color = colors.white
    }, {
        name = "|",
        width = 1,
        alignment = "center",
        color = colors.white
    }, {
        name = "Location (X, Y, Z)",
        width = 19,
        alignment = "center",
        color = colors.white
    }, {
        name = "|",
        width = 1,
        alignment = "center",
        color = colors.white
    }, {
        name = "Job",
        width = 15,
        alignment = "left",
        color = colors.white
    }, {
        name = "|",
        width = 1,
        alignment = "center",
        color = colors.white
    }, {
        name = "Status",
        width = 15,
        alignment = "center",
        color = colors.white
    }, {
        name = "|",
        width = 1,
        alignment = "center",
        color = colors.white
    }, {
        name = "Happiness",
        width = 10,
        alignment = "center",
        color = colors.white
    }, {
        name = "|",
        width = 1,
        alignment = "center",
        color = colors.white
    }, {
        name = "Commute",
        width = 10,
        alignment = "center",
        color = colors.white
    }}

    mon.clear()

    -- Write the table headings to the monitor
    for _, heading in ipairs(headings) do
        local headingText = string.sub(heading.name, 1, heading.width, heading.color)
        local headingLength = #headingText
        mon.setTextColor(heading.color)
        mon.setCursorPos(column, 2)
        mon.write("======================")

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
        -- Erstelle die neuen Anzeigen für den Bürger
        local id = citizen["id"]
        local displayName = citizen["name"]
        local locationX = FormatNumber(citizen["location"]["x"])
        local locationY = FormatNumber(citizen["location"]["y"])
        local locationZ = FormatNumber(citizen["location"]["z"])
        local job = citizen["work"] and citizen["work"]["type"] or nil
        local jobStatus = citizen["state"]
        local happiness = citizen["happiness"]
        local bedLocation = citizen["home"] and citizen["home"]["location"] or nil
        local workLocation = citizen["work"] and citizen["work"]["location"] or nil

        -- Write the citizen data to the monitor
        for _, heading in ipairs(headings) do
            local content = ""
            local contentAlignment = "left"

            if heading.name == "ID" then
                content = decimal_to_normal(id)
                contentAlignment = "center"
                contentColor = colors.white
            elseif heading.name == "|" then
                content = "|"
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

            -- Write the content
            if contentColor then
                mon.setTextColor(contentColor)
            end
            mon.write(content)

            column = column + heading.width + 1
        end

        row = row + 1
        counter = counter + 1
        column = 1
    end
end

while true do
    ShowCitizens()
    sleep(1)
end
