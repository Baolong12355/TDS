-- TDS Strategy Recorder - Record-only module, all GUI and visual mechanisms removed
-- Cleaned and formatted version

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteFunction = if not GameSpoof then ReplicatedStorage:WaitForChild("RemoteFunction") else SpoofEvent
local RemoteEvent = if not GameSpoof then ReplicatedStorage:WaitForChild("RemoteEvent") else SpoofEvent
local RSTimer = game:GetService("ReplicatedStorage").State.Timer.Time
local RSMode = ReplicatedStorage:WaitForChild("State"):WaitForChild("Mode")
local RSDifficulty = ReplicatedStorage:WaitForChild("State"):WaitForChild("Difficulty")
local RSMap = ReplicatedStorage:WaitForChild("State"):WaitForChild("Map")
local GameWave = LocalPlayer.PlayerGui:WaitForChild("ReactGameTopGameDisplay"):WaitForChild("Frame"):WaitForChild("wave"):WaitForChild("container"):WaitForChild("value")

-- File writing utilities
getgenv().WriteFile = function(check, name, location, str)
    if not check then return end
    
    if type(name) == "string" then
        if type(location) ~= "string" then location = "" end
        if not isfolder(location) then makefolder(location) end
        if type(str) ~= "string" then 
            error("Argument 4 must be a string got " .. tostring(str)) 
        end
        writefile(location.."/"..name..".txt", str)
    else
        error("Argument 2 must be a string got " .. tostring(name))
    end
end

getgenv().AppendFile = function(check, name, location, str)
    if not check then return end
    
    if type(name) == "string" then
        if type(location) ~= "string" then location = "" end
        if not isfolder(location) then WriteFile(check, name, location, str) end
        if type(str) ~= "string" then 
            error("Argument 4 must be a string got " .. tostring(str)) 
        end
        
        if isfile(location.."/"..name..".txt") then
            appendfile(location.."/"..name..".txt", str)
        else
            WriteFile(check, name, location, str)
        end
    else
        error("Argument 2 must be a string got " .. tostring(name))
    end
end

-- Strategy writing functions
local function writestrat(...)
    local args = {...}
    for i, v in ipairs(args) do
        args[i] = tostring(v)
    end
    return WriteFile(true, LocalPlayer.Name.."'s strat", "StrategiesX/TDS/Recorder", table.concat(args, " ").."\n")
end

local function appendstrat(...)
    local args = {...}
    for i, v in ipairs(args) do
        args[i] = tostring(v)
    end
    return AppendFile(true, LocalPlayer.Name.."'s strat", "StrategiesX/TDS/Recorder", table.concat(args, " ").."\n")
end

-- Global recorder object
getgenv().Recorder = {
    Troops = {
        Golden = {}
    },
    TowersList = {},
    SecondMili = 0
}
getgenv().TowersList = Recorder.TowersList

-- Timer utilities
function ConvertTimer(num)
    return math.floor(num/60), num % 60
end

local TimerCheck = false
function CheckTimer(bool)
    return (bool and TimerCheck) or true
end

-- Timer event handlers
RSTimer.Changed:Connect(function(time)
    TimerCheck = (time == 5) and true or false
end)

RSTimer.Changed:Connect(function()
    Recorder.SecondMili = 0
    for _ = 1, 9 do
        task.wait(0.09)
        Recorder.SecondMili += 0.1
    end
end)

function GetTimer()
    local min, sec = ConvertTimer(RSTimer.Value)
    return {tonumber(GameWave.Text), min, sec + Recorder.SecondMili, tostring(TimerCheck)}
end

-- Tower tracking
local TowerCount = 0
local GetMode
local function SetStatus(_) end -- GUI removed

-- Action generators
local GenerateFunction = {
    Place = function(Args, Timer, RemoteCheck)
        if typeof(RemoteCheck) ~= "Instance" then return end
        
        local TowerName = Args[3]
        local Position = Args[4].Position
        local Rotation = Args[4].Rotation
        local RotateX, RotateY, RotateZ = Rotation:ToEulerAnglesYXZ()
        
        TowerCount += 1
        RemoteCheck.Name = TowerCount
        TowersList[TowerCount] = {
            ["TowerName"] = TowerName,
            ["Instance"] = RemoteCheck,
            ["Position"] = Position,
            ["Rotation"] = Rotation,
        }
        
        SetStatus("Placed " .. TowerName)
        appendstrat(string.format('TDS:Place("%s", %s, %s, %s, %s, %s, %s, %s)', 
            TowerName, Position.X, Position.Y, Position.Z, 
            table.concat(Timer, ", "), RotateX, RotateY, RotateZ))
    end,
    
    Upgrade = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local PathTarget = Args[4].Path
        
        if RemoteCheck ~= true then
            SetStatus("Upgrade Failed " .. TowerIndex)
            return
        end
        
        SetStatus("Upgraded " .. TowerIndex)
        appendstrat(string.format('TDS:Upgrade(%s, %s, %s)', 
            TowerIndex, table.concat(Timer, ", "), PathTarget))
    end,
    
    Sell = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[3].Troop.Name
        
        if not RemoteCheck or TowersList[tonumber(TowerIndex)].Instance:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        SetStatus("Sold " .. TowerIndex)
        appendstrat(string.format('TDS:Sell(%s, %s)', 
            TowerIndex, table.concat(Timer, ", ")))
    end,
    
    Target = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local Target = Args[4].Target
        
        if RemoteCheck ~= true then return end
        
        SetStatus("Target " .. TowerIndex)
        appendstrat(string.format('TDS:Target(%s, "%s", %s)', 
            TowerIndex, Target, table.concat(Timer, ", ")))
    end,
    
    Abilities = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local AbilityName = Args[4].Name
        local Data = Args[4].Data
        
        if RemoteCheck ~= true then return end
        
        local formatData = function(d)
            local out = {}
            for k, v in pairs(d) do
                if k == "directionCFrame" then
                    table.insert(out, string.format('["%s"] = CFrame.new(%s)', k, tostring(v)))
                elseif k == "position" then
                    table.insert(out, string.format('["%s"] = Vector3.new(%s)', k, tostring(v)))
                else
                    table.insert(out, string.format('["%s"] = %s', k, tostring(v)))
                end
            end
            return "{" .. table.concat(out, ", ") .. "}"
        end
        
        appendstrat(string.format('TDS:Ability(%s, "%s", %s, %s)', 
            TowerIndex, AbilityName, table.concat(Timer, ", "), formatData(Data)))
    end,
    
    Option = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local OptionName = Args[4].Name
        local Value = Args[4].Value
        
        if RemoteCheck ~= true then return end
        
        appendstrat(string.format('TDS:Option(%s, "%s", "%s", %s)', 
            TowerIndex, OptionName, Value, table.concat(Timer, ", ")))
    end,
    
    Skip = function(_, Timer, _)
        appendstrat(string.format('TDS:Skip(%s)', table.concat(Timer, ", ")))
    end,
    
    Vote = function(Args, _, _)
        local Difficulty = Args[3]
        local DiffTable = {
            Easy = "Easy",
            Casual = "Casual",
            Intermediate = "Intermediate",
            Molten = "Molten",
            Fallen = "Fallen"
        }
        GetMode = DiffTable[Difficulty] or Difficulty
    end,
}

-- Initialize troops from inventory
for TowerName, Tower in next, ReplicatedStorage.RemoteFunction:InvokeServer("Session", "Search", "Inventory.Troops") do
    if Tower.Equipped then
        table.insert(Recorder.Troops, TowerName)
        if Tower.GoldenPerks then
            table.insert(Recorder.Troops.Golden, TowerName)
        end
    end
end

-- Write initial strategy header
writestrat('getgenv().StratCreditsAuthor = "Optional"')
appendstrat(string.format(
    'local TDS = loadstring(game:HttpGet("https://raw.githubusercontent.com/TDSX1/Strategies-X/main/TDS/MainSource.lua", true))()\nTDS:Map("%s", true, "%s")\nTDS:Loadout({"%s"%s})',
    RSMap.Value,
    RSMode.Value,
    table.concat(Recorder.Troops, '", "'),
    (#Recorder.Troops.Golden ~= 0 and '", ["Golden"] = {"' .. table.concat(Recorder.Troops.Golden, '", "') .. '"}' or "")
))

-- Handle difficulty setting
local DiffTable = {
    Easy = "Easy",
    Casual = "Casual",
    Intermediate = "Intermediate",
    Molten = "Molten",
    Fallen = "Fallen"
}

task.spawn(function()
    repeat task.wait() until GetMode or RSDifficulty.Value ~= ""
    local diff = GetMode or DiffTable[RSDifficulty.Value]
    if diff then
        appendstrat(string.format('TDS:Mode("%s")', diff))
    end
end)

-- Hook remote function calls
local OldNamecall
OldNamecall = hookmetamethod(game, '__namecall', function(...)
    local self, args = (...), ({select(2, ...)})
    
    if getnamecallmethod() == "InvokeServer" and self.Name == "RemoteFunction" then
        local thread = coroutine.running()
        coroutine.wrap(function()
            local timer = GetTimer()
            local result = self.InvokeServer(self, unpack(args))
            if GenerateFunction[args[2]] then
                GenerateFunction[args[2]](args, timer, result)
            end
            coroutine.resume(thread, result)
        end)()
        return coroutine.yield()
    end
    
    return OldNamecall(...)
end)