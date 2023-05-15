-- Config
local sortOpt = "ID" -- There are options to sort the Table by "Job; Name; ID"


-- Startup Stuff
local colony = peripheral.find("colonyIntegrator")
if not colony then error("Colony Integrator not found.") end
if not colony.isInColony then error("Colony Integrator is not in a colony.") end
print("Colony Integrator initialized.")

local mon = peripheral.find("monitor")
if not mon then error("Monitor not found.") end
print("Monitor initialized.")
-- End Startup Stuff

function SortTable(a, b)
  if sortOpt == "Job" then
    local aJob = a["work"] and a["work"]["type"] or nil
    local bJob = b["work"] and b["work"]["type"] or nil
    if (a == nil or aJob == nil) then return false end
    if (b == nil or bJob == nil) then return false end
    return aJob < bJob
  elseif sortOpt == "Name" then
    local aName = a["name"]
    local bN = b["name"]
    if aName == nil then return false end
    if bN == nil then return false end
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
    return string.format("%.0f", num)
  end
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
  if (happiness == 10.0) then
    mon.setTextColor(colors.green)
  else
    mon.setTextColor(colors.pink)
  end
  mon.write(happiness)
end

function GetJobStatus(status)
  local statusText = {
    ["Working"] = "Working",
    ["Farming"] = "Working",
    ["Delivering"] = "Working",
    ["Mining"] = "Working",
    ["Composting"] = "Working",
    ["Searching for trees"] = "Working"
  }

  if (statusText[status] == nil) then
    mon.setTextColor(colors.red)
    mon.write(status)
  else
    mon.setTextColor(colors.green)
    mon.write(statusText[status])
  end
end

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
  if (jobColors[job] == nil) then
    mon.setTextColor(colors.blue)
  else
    mon.setTextColor(jobColors[job])
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
    local mult = 10 -- # of decimal places
    distance = math.floor(distance * mult + 0.5) / mult

    mon.setTextColor(colors.green)
    if (distance > 99) then
      mon.setTextColor(colors.red)
    end
    if (distance > 75 and distance < 100) then
      mon.setTextColor(colors.orange)
    end
    if (distance > 50 and distance < 76) then
      mon.setTextColor(colors.yellow)
    end
    mon.write(distance)
  end
end

function ShowCitizens()
  local counter = 1
  local row = 1
  local column = 1
  local citizens = colony.getCitizens()
  table.sort(citizens, SortTable)

  -- Define the table headings
  local headings = {
    { name = "ID", width = 3 },
    { name = "|", width = 1 },
    { name = "Name", width = 10 },
    { name = "|", width = 1 },
    { name = "Location (X, Y, Z)", width = 19 },
    { name = "|", width = 1 },
    { name = "Job", width = 15 },
    { name = "|", width = 1 },
    { name = "Status", width = 15 },
    { name = "|", width = 1 },
    { name = "Happiness", width = 10 },
    { name = "|", width = 1 },
    { name = "Commute", width = 20 }
  }

  mon.clear()

  -- Write the table headings to the monitor
  for _, heading in ipairs(headings) do
    mon.setCursorPos(column, row)
    mon.setTextColor(colors.white)
    mon.write(string.sub(heading.name, 1, heading.width))
    column = column + heading.width + 1
  end

  row = row + 2
  column = 1

  for _, citizen in ipairs(citizens) do
    -- Erstelle die neuen Anzeigen für den Bürger
    local id = citizen["id"]
    local displayName = citizen["name"]
    local locationX = citizen["location"]["x"]
    local locationY = citizen["location"]["y"]
    local locationZ = citizen["location"]["z"]
    local job = citizen["work"] and citizen["work"]["type"] or nil
    local jobStatus = citizen["state"]
    local happiness = citizen["happiness"]
    local bedLocation = citizen["home"] and citizen["home"]["location"] or nil
    local workLocation = citizen["work"] and citizen["work"]["location"] or nil

    -- Write the citizen data to the monitor
    for _, heading in ipairs(headings) do
      mon.setCursorPos(column, 2)
      mon.setTextColor(colors.white)
      mon.write("======================")
      mon.setCursorPos(column, row)
      if heading.name == "ID" then
        mon.setTextColor(colors.white)
        mon.write(decimal_to_normal(id))
      elseif heading.name == "|" then
        mon.setTextColor(colors.white)
        mon.write("|")
      elseif heading.name == "Name" then
        mon.setTextColor(colors.blue)
        mon.write(FirstName(displayName))
      elseif heading.name == "|" then
        mon.setTextColor(colors.white)
        mon.write("|")
      elseif heading.name == "Location (X, Y, Z)" then
        mon.setTextColor(colors.white)
        mon.write("(" .. locationX .. ", " .. locationY .. ", " .. locationZ .. ")")
      elseif heading.name == "|" then
        mon.setTextColor(colors.white)
        mon.write("|")
      elseif heading.name == "Job" then
        SetJobColor(job)
        mon.write(firstToUpper(job or ""))
      elseif heading.name == "|" then
        mon.setTextColor(colors.white)
        mon.write("|")
      elseif heading.name == "Status" then
        GetJobStatus(jobStatus)
      elseif heading.name == "|" then
        mon.setTextColor(colors.white)
        mon.write("|")
      elseif heading.name == "Happiness" then
        GetHappiness(happiness)
      elseif heading.name == "|" then
        mon.setTextColor(colors.white)
        mon.write("|")
      elseif heading.name == "Commute" then
        GetBedDistance(bedLocation, workLocation)
      end
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