--[[
    TDS Strategy Recorder
    Author: [Your Name]
    Description: Records TDS gameplay and generates strategy scripts
    Compatible with: Synapse X, KRNL, Script-Ware, Fluxus, etc.
    GitHub Ready: Yes
--]]

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Security check
if not LocalPlayer then
    warn("LocalPlayer not found!")
    return
end

-- Game elements
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local RSTimer = ReplicatedStorage:WaitForChild("State"):WaitForChild("Timer"):WaitForChild("Time")
local RSMode = ReplicatedStorage:WaitForChild("State"):WaitForChild("Mode")
local RSDifficulty = ReplicatedStorage:WaitForChild("State"):WaitForChild("Difficulty")
local RSMap = ReplicatedStorage:WaitForChild("State"):WaitForChild("Map")

-- Wait for GUI elements
local success, VoteGUI = pcall(function()
    return LocalPlayer.PlayerGui:WaitForChild("ReactOverridesVote"):WaitForChild("Frame"):WaitForChild("votes"):WaitForChild("vote")
end)
if not success then
    warn("Vote GUI not found, auto-skip will be disabled")
end

local success2, GameWave = pcall(function()
    return LocalPlayer.PlayerGui:WaitForChild("ReactGameTopGameDisplay"):WaitForChild("Frame"):WaitForChild("wave"):WaitForChild("container"):WaitForChild("value")
end)
if not success2 then
    warn("Game Wave GUI not found, some features may not work")
end

-- File handling functions
getgenv().WriteFile = function(check, name, location, str)
    if not check then return end
    
    if type(name) ~= "string" then
        error("Argument 2 must be a string, got " .. type(name))
    end
    
    if type(location) ~= "string" then
        location = ""
    end
    
    if not isfolder(location) then
        makefolder(location)
    end
    
    if type(str) ~= "string" then
        error("Argument 4 must be a string, got " .. type(str))
    end
    
    writefile(location.."/"..name..".txt", str)
end

getgenv().AppendFile = function(check, name, location, str)
    if not check then return end
    
    if type(name) ~= "string" then
        error("Argument 2 must be a string, got " .. type(name))
    end
    
    if type(location) ~= "string" then
        location = ""
    end
    
    if not isfolder(location) then
        WriteFile(check, name, location, str)
        return
    end
    
    if type(str) ~= "string" then
        error("Argument 4 must be a string, got " .. type(str))
    end
    
    if isfile(location.."/"..name..".txt") then
        appendfile(location.."/"..name..".txt", str)
    else
        WriteFile(check, name, location, str)
    end
end

-- Strategy writing functions
local function writestrat(...)
    local TableText = {...}
    task.spawn(function()
        for i, v in pairs(TableText) do
            if type(v) ~= "string" then
                TableText[i] = tostring(v)
            end
        end
        local Text = table.concat(TableText, " ")
        print("[RECORDER] " .. Text)
        WriteFile(true, LocalPlayer.Name.."'s strat", "StrategiesX/TDS/Recorder", Text.."\n")
    end)
end

local function appendstrat(...)
    local TableText = {...}
    task.spawn(function()
        for i, v in pairs(TableText) do
            if type(v) ~= "string" then
                TableText[i] = tostring(v)
            end
        end
        local Text = table.concat(TableText, " ")
        print("[RECORDER] " .. Text)
        AppendFile(true, LocalPlayer.Name.."'s strat", "StrategiesX/TDS/Recorder", Text.."\n")
    end)
end

-- Recorder globals
getgenv().Recorder = {
    Troops = {
        Golden = {},
    },
    TowersList = {},
    SecondMili = 0,
    Status = {Text = "Initializing..."}
}

getgenv().TowersList = Recorder.TowersList
local TowerCount = 0
local GetMode = nil

-- Load UI Library
local UILibrary
pcall(function()
    UILibrary = getgenv().UILibrary or loadstring(game:HttpGet("https://raw.githubusercontent.com/Sigmanic/ROBLOX/main/ModificationWallyUi", true))()
    UILibrary.options.toggledisplay = 'Fill'
    
    local mainwindow = UILibrary:CreateWindow('TDS Recorder')
    UILibrary.container.Parent.Parent = LocalPlayer.PlayerGui
    Recorder.Status = mainwindow:Section("Loading...")
    
    -- Time tracking
    local timeSection = mainwindow:Section("Time Passed: 00:00")
    task.spawn(function()
        local function TimeConverter(v)
            return v <= 9 and "0" .. v or tostring(v)
        end
        local startTime = os.time()
        
        while task.wait(0.1) do
            local t = os.time() - startTime
            local seconds = t % 60
            local minutes = math.floor(t / 60) % 60
            timeSection.Text = "Time Passed: " .. TimeConverter(minutes) .. ":" .. TimeConverter(seconds)
        end
    end)
    
    -- UI Controls
    mainwindow:Toggle('Auto Skip', {flag = "autoskip"})
    mainwindow:Section("\\/ LAST WAVE \\/")
    mainwindow:Toggle('Auto Sell Farms', {default = true, flag = "autosellfarms"})
end)

-- Status function
local function SetStatus(string)
    if Recorder.Status then
        Recorder.Status.Text = string
    end
    print("[RECORDER STATUS] " .. string)
end

-- Timer functions
local function ConvertTimer(number)
   return math.floor(number/60), number % 60
end

local TimerCheck = false
RSTimer.Changed:Connect(function(time)
    if time == 5 then
        TimerCheck = true
    elseif time and time > 5 then
        TimerCheck = false
    end
end)

local function GetTimer()
    local Min, Sec = ConvertTimer(RSTimer.Value)
    local wave = GameWave and tonumber(GameWave.Text) or 0
    return {wave, Min, Sec + Recorder.SecondMili, tostring(TimerCheck)}
end

-- Second millisecond tracking
RSTimer.Changed:Connect(function()
    Recorder.SecondMili = 0
    for i = 1, 9 do
        task.wait(0.09)
        Recorder.SecondMili += 0.1
    end
end)

-- Main recording functions
local GenerateFunction = {
    Place = function(Args, Timer, RemoteCheck)
        if typeof(RemoteCheck) ~= "Instance" then
            return
        end
        
        local TowerName = Args[3]
        local Position = Args[4].Position
        local Rotation = Args[4].Rotation
        local RotateX, RotateY, RotateZ = Rotation:ToEulerAnglesYXZ()
        
        TowerCount += 1
        RemoteCheck.Name = TowerCount
        TowersList[TowerCount] = {
            ["TowerName"] = Args[3],
            ["Instance"] = RemoteCheck,
            ["Position"] = Position,
            ["Rotation"] = Rotation,
        }
        
        -- Safe upgrade handler call
        pcall(function()
            local upgradeHandler = require(ReplicatedStorage.Client.Modules.Game.Interface.Elements.Upgrade.upgradeHandler)
            upgradeHandler:selectTroop(RemoteCheck)
        end)
        
        SetStatus(`Placed {TowerName}`)
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Place("{TowerName}", {Position.X}, {Position.Y}, {Position.Z}, {TimerStr}, {RotateX}, {RotateY}, {RotateZ})`)
    end,
    
    Upgrade = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local PathTarget = Args[4].Path
        
        if RemoteCheck ~= true then
            SetStatus(`Upgrade Failed ID: {TowerIndex}`)
            return
        end
        
        SetStatus(`Upgraded ID: {TowerIndex}`)
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Upgrade({TowerIndex}, {TimerStr}, {PathTarget})`)
    end,
    
    Sell = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[3].Troop.Name
        
        if not RemoteCheck then
            SetStatus(`Sell Failed ID: {TowerIndex}`)
            return
        end
        
        SetStatus(`Sold Tower ID: {TowerIndex}`)
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Sell({TowerIndex}, {TimerStr})`)
    end,
    
    Target = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local Target = Args[4].Target
        
        if RemoteCheck ~= true then
            SetStatus(`Target Failed ID: {TowerIndex}`)
            return
        end
        
        SetStatus(`Changed Target ID: {TowerIndex}`)
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Target({TowerIndex}, "{Target}", {TimerStr})`)
    end,
    
    Abilities = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local AbilityName = Args[4].Name
        local Data = Args[4].Data
        
        if RemoteCheck ~= true then
            SetStatus(`Ability Failed ID: {TowerIndex}`)
            return
        end
        
        local function formatData(Data)
            local formattedData = {}
            for key, value in pairs(Data) do
                if key == "directionCFrame" then
                    table.insert(formattedData, string.format('["%s"] = CFrame.new(%s)', key, tostring(value)))
                elseif key == "position" then
                    table.insert(formattedData, string.format('["%s"] = Vector3.new(%s)', key, tostring(value)))
                else
                    table.insert(formattedData, string.format('["%s"] = %s', key, tostring(value)))
                end
            end
            return "{" .. table.concat(formattedData, ", ") .. "}"
        end
        
        local formattedData = formatData(Data)
        SetStatus(`Used Ability: {AbilityName} on ID: {TowerIndex}`)
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Ability({TowerIndex}, "{AbilityName}", {TimerStr}, {formattedData})`)
    end,
    
    Option = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local OptionName = Args[4].Name
        local Value = Args[4].Value
        
        if RemoteCheck ~= true then
            SetStatus(`Option Failed ID: {TowerIndex}`)
            return
        end
        
        SetStatus(`Used Option: {OptionName} on ID: {TowerIndex}`)
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Option({TowerIndex}, "{OptionName}", "{Value}", {TimerStr})`)
    end,
    
    Skip = function(Args, Timer, RemoteCheck)
        SetStatus(`Skipped Wave`)
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Skip({TimerStr})`)
    end,
    
    Vote = function(Args, Timer, RemoteCheck)
        local Difficulty = Args[3]
        local DiffTable = {
            ["Easy"] = "Easy",
            ["Casual"] = "Casual",
            ["Intermediate"] = "Intermediate",
            ["Molten"] = "Molten",
            ["Fallen"] = "Fallen"
        }
        GetMode = DiffTable[Difficulty] or Difficulty
        SetStatus(`Voted: {GetMode}`)
    end,
}

-- Auto skip functionality
if VoteGUI then
    local Skipped = false
    VoteGUI:GetPropertyChangedSignal("Position"):Connect(function()
        if not UILibrary or not UILibrary.flags or not UILibrary.flags.autoskip then
            return
        end
        
        if Skipped or VoteGUI:WaitForChild("count").Text ~= "0/1 Required" then
            return
        end
        
        local currentPrompt = VoteGUI:WaitForChild("prompt").Text
        if currentPrompt == "Skip Wave?" and GameWave and tonumber(GameWave.Text) ~= 0 then
            Skipped = true
            local Timer = GetTimer()
            task.spawn(GenerateFunction["Skip"], true, Timer)
            RemoteFunction:InvokeServer("Voting", "Skip")
            task.wait(2.5)
            Skipped = false
        end
    end)
end

-- Auto sell farms on final wave
if GameWave then
    task.spawn(function()
        GameWave:GetPropertyChangedSignal("Text"):Wait()
        local FinalWaveAtDifferentMode = {
            ["Easy"] = 25,
            ["Casual"] = 30,
            ["Intermediate"] = 30,
            ["Molten"] = 35,
            ["Fallen"] = 40,
            ["Hardcore"] = 50
        }
        
        GameWave:GetPropertyChangedSignal("Text"):Connect(function()
            local FinalWave = FinalWaveAtDifferentMode[RSDifficulty.Value]
            if tonumber(GameWave.Text) == FinalWave then
                if UILibrary and UILibrary.flags and UILibrary.flags.autosellfarms then
                    for i, v in ipairs(Workspace.Towers:GetChildren()) do
                        if v.Owner.Value == LocalPlayer.UserId and v:WaitForChild("TowerReplicator"):GetAttribute("Type") == "Farm" then
                            RemoteFunction:InvokeServer("Troops", "Sell", {["Troop"] = v})
                        end
                    end
                    SetStatus(`Auto-sold all farms`)
                end
            end
        end)
    end)
end

-- Initialize strategy file
task.spawn(function()
    -- Get equipped troops
    local success, result = pcall(function()
        return RemoteFunction:InvokeServer("Session", "Search", "Inventory.Troops")
    end)
    
    if success then
        for TowerName, Tower in pairs(result) do
            if Tower.Equipped then
                table.insert(Recorder.Troops, TowerName)
                if Tower.GoldenPerks then
                    table.insert(Recorder.Troops.Golden, TowerName)
                end
            end
        end
    end
    
    -- Write strategy header
    writestrat("getgenv().StratCreditsAuthor = \"TDS Recorder\"")
    appendstrat("local TDS = loadstring(game:HttpGet(\"https://raw.githubusercontent.com/TDSX1/Strategies-X/main/TDS/MainSource.lua\", true))()")
    appendstrat(`TDS:Map("{RSMap.Value}", true, "{RSMode.Value}")`)
    
    local loadoutStr = `TDS:Loadout({"` .. table.concat(Recorder.Troops, `", "`) .. `"`
    if #Recorder.Troops.Golden ~= 0 then
        loadoutStr = loadoutStr .. `, ["Golden"] = {"` .. table.concat(Recorder.Troops.Golden, `", "`) .. `"}`
    end
    loadoutStr = loadoutStr .. "})"
    appendstrat(loadoutStr)
    
    -- Set difficulty
    task.spawn(function()
        local DiffTable = {
            ["Easy"] = "Easy",
            ["Casual"] = "Casual",
            ["Intermediate"] = "Intermediate",
            ["Molten"] = "Molten",
            ["Fallen"] = "Fallen"
        }
        
        repeat task.wait() until GetMode ~= nil or RSDifficulty.Value ~= ""
        
        if GetMode then
            repeat task.wait() until GetMode == RSDifficulty.Value
            appendstrat(`TDS:Mode("{GetMode}")`)
        elseif DiffTable[RSDifficulty.Value] then
            appendstrat(`TDS:Mode("{DiffTable[RSDifficulty.Value]}")`)
        end
    end)
end)

-- Hook RemoteFunction
local OldNamecall
OldNamecall = hookmetamethod(game, '__namecall', function(...)
    local Self, Args = (...), ({select(2, ...)})
    
    if getnamecallmethod() == "InvokeServer" and Self.name == "RemoteFunction" then
        local thread = coroutine.running()
        coroutine.wrap(function(Args)
            local Timer = GetTimer()
            local RemoteFired = Self.InvokeServer(Self, unpack(Args))
            
            if GenerateFunction[Args[2]] then
                task.spawn(GenerateFunction[Args[2]], Args, Timer, RemoteFired)
            end
            
            coroutine.resume(thread, RemoteFired)
        end)(Args)
        return coroutine.yield()
    end
    
    return OldNamecall(..., unpack({select(2, ...)}))
end)

-- Success message
SetStatus("TDS Recorder Active!")
print("=== TDS RECORDER STARTED ===")
print("Strategy files will be saved to: workspace/StrategiesX/TDS/Recorder/")
print("File name: " .. LocalPlayer.Name .. "'s strat.txt")
print("Author: TDS Recorder")
print("Compatible with GitHub!")
print("===============================")

-- Anti-detection (optional)
task.spawn(function()
    while task.wait(30) do
        SetStatus("Recording... " .. os.date("%H:%M:%S"))
    end
end)