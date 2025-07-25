--[[
    TDS Strategy Recorder - LIGHTWEIGHT VERSION
    Tối ưu cho executor yếu (KRNL, Fluxus, JJSploit, etc.)
    Bỏ UI phức tạp, chỉ giữ core recording
--]]

-- Basic services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Check executor compatibility
if not hookmetamethod or not writefile or not isfolder then
    warn("Executor không hỗ trợ đầy đủ! Cần: hookmetamethod, writefile, isfolder")
    return
end

print("=== TDS RECORDER KHỞI ĐỘNG ===")
print("Phiên bản nhẹ cho executor yếu")

-- Wait for game elements with timeout
local function SafeWaitForChild(parent, name, timeout)
    timeout = timeout or 10
    local start = tick()
    while tick() - start < timeout do
        local child = parent:FindFirstChild(name)
        if child then return child end
        wait(0.1)
    end
    return nil
end

-- Game elements
local RemoteFunction = SafeWaitForChild(ReplicatedStorage, "RemoteFunction", 5)
if not RemoteFunction then
    warn("Không tìm thấy RemoteFunction! Game chưa load xong?")
    return
end

local RSTimer = SafeWaitForChild(ReplicatedStorage:WaitForChild("State"):WaitForChild("Timer"), "Time", 5)
local RSMode = SafeWaitForChild(ReplicatedStorage:WaitForChild("State"), "Mode", 5)
local RSDifficulty = SafeWaitForChild(ReplicatedStorage:WaitForChild("State"), "Difficulty", 5)
local RSMap = SafeWaitForChild(ReplicatedStorage:WaitForChild("State"), "Map", 5)

-- Simple file functions
local function WriteFile(name, str)
    local folder = "TDS_Recorder"
    if not isfolder(folder) then
        makefolder(folder)
    end
    writefile(folder.."/"..name..".txt", str)
end

local function AppendFile(name, str)
    local folder = "TDS_Recorder"
    if not isfolder(folder) then
        makefolder(folder)
    end
    local path = folder.."/"..name..".txt"
    if isfile(path) then
        appendfile(path, str)
    else
        WriteFile(name, str)
    end
end

-- Simple recorder
local Recorder = {
    Troops = {},
    Golden = {},
    SecondMili = 0,
    TowerCount = 0,
    TowersList = {}
}

local function Log(msg)
    print("[RECORDER] " .. msg)
end

-- Timer functions
local function ConvertTimer(number)
   return math.floor(number/60), number % 60
end

local TimerCheck = false
if RSTimer then
    RSTimer.Changed:Connect(function(time)
        TimerCheck = (time == 5)
    end)
    
    RSTimer.Changed:Connect(function()
        Recorder.SecondMili = 0
        for i = 1, 9 do
            wait(0.09)
            Recorder.SecondMili = Recorder.SecondMili + 0.1
        end
    end)
end

local function GetTimer()
    if not RSTimer then return {0, 0, 0, "false"} end
    
    local Min, Sec = ConvertTimer(RSTimer.Value)
    local wave = 0
    
    -- Try to get wave safely
    pcall(function()
        local waveGui = LocalPlayer.PlayerGui:FindFirstChild("ReactGameTopGameDisplay")
        if waveGui then
            local waveText = waveGui.Frame.wave.container.value.Text
            wave = tonumber(waveText) or 0
        end
    end)
    
    return {wave, Min, Sec + Recorder.SecondMili, tostring(TimerCheck)}
end

-- Simple recording functions
local RecordFunctions = {
    Place = function(args, timer)
        local name = args[3]
        local pos = args[4].Position
        local rot = args[4].Rotation
        local rx, ry, rz = rot:ToEulerAnglesYXZ()
        
        Recorder.TowerCount = Recorder.TowerCount + 1
        Recorder.TowersList[Recorder.TowerCount] = {name = name, pos = pos}
        
        Log("Placed: " .. name)
        local t = table.concat(timer, ", ")
        AppendFile(LocalPlayer.Name, string.format('TDS:Place("%s", %.1f, %.1f, %.1f, %s, %.2f, %.2f, %.2f)\n', 
            name, pos.X, pos.Y, pos.Z, t, rx, ry, rz))
    end,
    
    Upgrade = function(args, timer, result)
        if result ~= true then return end
        local id = args[4].Troop.Name
        local path = args[4].Path
        Log("Upgraded ID: " .. id)
        local t = table.concat(timer, ", ")
        AppendFile(LocalPlayer.Name, string.format('TDS:Upgrade(%s, %s, %s)\n', id, t, path))
    end,
    
    Sell = function(args, timer, result)
        if not result then return end
        local id = args[3].Troop.Name
        Log("Sold ID: " .. id)
        local t = table.concat(timer, ", ")
        AppendFile(LocalPlayer.Name, string.format('TDS:Sell(%s, %s)\n', id, t))
    end,
    
    Target = function(args, timer, result)
        if result ~= true then return end
        local id = args[4].Troop.Name
        local target = args[4].Target
        Log("Target changed ID: " .. id)
        local t = table.concat(timer, ", ")
        AppendFile(LocalPlayer.Name, string.format('TDS:Target(%s, "%s", %s)\n', id, target, t))
    end,
    
    Skip = function(args, timer)
        Log("Skipped wave")
        local t = table.concat(timer, ", ")
        AppendFile(LocalPlayer.Name, string.format('TDS:Skip(%s)\n', t))
    end
}

-- Get loadout (simple version)
local function GetLoadout()
    local success, result = pcall(function()
        return RemoteFunction:InvokeServer("Session", "Search", "Inventory.Troops")
    end)
    
    if not success then
        Log("Không thể lấy loadout")
        return
    end
    
    for name, tower in pairs(result) do
        if tower.Equipped then
            table.insert(Recorder.Troops, name)
            if tower.GoldenPerks then
                table.insert(Recorder.Golden, name)
            end
        end
    end
end

-- Initialize
local function Initialize()
    GetLoadout()
    
    -- Write header
    WriteFile(LocalPlayer.Name, 'getgenv().StratCreditsAuthor = "TDS Recorder Lite"\n')
    AppendFile(LocalPlayer.Name, 'local TDS = loadstring(game:HttpGet("https://raw.githubusercontent.com/TDSX1/Strategies-X/main/TDS/MainSource.lua", true))()\n')
    
    if RSMap then
        AppendFile(LocalPlayer.Name, string.format('TDS:Map("%s", true, "%s")\n', RSMap.Value, RSMode and RSMode.Value or ""))
    end
    
    -- Loadout
    if #Recorder.Troops > 0 then
        local loadout = 'TDS:Loadout({"' .. table.concat(Recorder.Troops, '", "') .. '"'
        if #Recorder.Golden > 0 then
            loadout = loadout .. ', ["Golden"] = {"' .. table.concat(Recorder.Golden, '", "') .. '"}'
        end
        loadout = loadout .. '})\n'
        AppendFile(LocalPlayer.Name, loadout)
    end
    
    -- Difficulty
    if RSDifficulty and RSDifficulty.Value ~= "" then
        AppendFile(LocalPlayer.Name, string.format('TDS:Mode("%s")\n', RSDifficulty.Value))
    end
    
    Log("Khởi tạo hoàn tất!")
end

-- Main hook (simplified)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(...)
    local self, args = (...), {select(2, ...)}
    
    if getnamecallmethod() == "InvokeServer" and self == RemoteFunction then
        local action = args[2]
        local timer = GetTimer()
        
        -- Call original first
        local result = oldNamecall(self, unpack(args))
        
        -- Record action
        if RecordFunctions[action] then
            spawn(function()
                RecordFunctions[action](args, timer, result)
            end)
        end
        
        return result
    end
    
    return oldNamecall(...)
end)

-- Auto skip (optional, lightweight)
spawn(function()
    while wait(1) do
        pcall(function()
            local voteGui = LocalPlayer.PlayerGui:FindFirstChild("ReactOverridesVote")
            if voteGui then
                local vote = voteGui.Frame.votes.vote
                if vote.prompt.Text == "Skip Wave?" and vote.count.Text == "0/1 Required" then
                    RemoteFunction:InvokeServer("Voting", "Skip")
                    wait(3)
                end
            end
        end)
    end
end)

-- Auto sell farms on final wave
spawn(function()
    while wait(2) do
        pcall(function()
            if not RSDifficulty then return end
            
            local finalWaves = {
                Easy = 25, Casual = 30, Intermediate = 30, 
                Molten = 35, Fallen = 40, Hardcore = 50
            }
            
            local waveGui = LocalPlayer.PlayerGui:FindFirstChild("ReactGameTopGameDisplay")
            if waveGui then
                local currentWave = tonumber(waveGui.Frame.wave.container.value.Text)
                local finalWave = finalWaves[RSDifficulty.Value]
                
                if currentWave == finalWave then
                    for _, tower in pairs(game.Workspace.Towers:GetChildren()) do
                        if tower.Owner.Value == LocalPlayer.UserId then
                            local towerType = tower:FindFirstChild("TowerReplicator")
                            if towerType and towerType:GetAttribute("Type") == "Farm" then
                                RemoteFunction:InvokeServer("Troops", "Sell", {Troop = tower})
                            end
                        end
                    end
                    Log("Auto-sold all farms!")
                    wait(5)
                end
            end
        end)
    end
end)

-- Start recording
Initialize()

print("=== RECORDER HOẠT ĐỘNG ===")
print("File lưu tại: workspace/TDS_Recorder/" .. LocalPlayer.Name .. ".txt")
print("Nhẹ nhàng, ít lag!")
print("=========================")

-- Keep alive
spawn(function()
    while wait(60) do
        Log("Still recording... " .. os.date("%H:%M"))
    end
end)