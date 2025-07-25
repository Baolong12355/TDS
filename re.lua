-- Cleaned-up version: removed GUI elements (ReactOverridesVote, ReactGameTopGameDisplay, UILibrary UI) -- Kept recording, write, append logic intact for backend-only use

local Workspace = game:GetService("Workspace") local Players = game:GetService("Players") local LocalPlayer = Players.LocalPlayer local ReplicatedStorage = game:GetService("ReplicatedStorage") local RemoteFunction = if not GameSpoof then ReplicatedStorage:WaitForChild("RemoteFunction") else SpoofEvent local RemoteEvent = if not GameSpoof then ReplicatedStorage:WaitForChild("RemoteEvent") else SpoofEvent local RSTimer = ReplicatedStorage:WaitForChild("State"):WaitForChild("Timer"):WaitForChild("Time") local RSMode = ReplicatedStorage:WaitForChild("State"):WaitForChild("Mode") local RSDifficulty = ReplicatedStorage:WaitForChild("State"):WaitForChild("Difficulty") local RSMap = ReplicatedStorage:WaitForChild("State"):WaitForChild("Map") local GameWave = LocalPlayer.PlayerGui:WaitForChild("ReactGameTopGameDisplay"):WaitForChild("Frame"):WaitForChild("wave"):WaitForChild("container"):WaitForChild("value")

getgenv().WriteFile = function(check,name,location,str) if not check then return end if type(name) == "string" then if type(location) ~= "string" then location = "" end if not isfolder(location) then makefolder(location) end if type(str) ~= "string" then error("Argument 4 must be a string got " .. tostring(str)) end writefile(location.."/"..name..".txt",str) else error("Argument 2 must be a string got " .. tostring(name)) end end

getgenv().AppendFile = function(check,name,location,str) if not check then return end if type(name) == "string" then if type(location) ~= "string" then location = "" end if not isfolder(location) then WriteFile(check,name,location,str) end if type(str) ~= "string" then error("Argument 4 must be a string got " .. tostring(str)) end if isfile(location.."/"..name..".txt") then appendfile(location.."/"..name..".txt",str) else WriteFile(check,name,location,str) end else error("Argument 2 must be a string got " .. tostring(name)) end end

local function writestrat(...) local args = {...} for i,v in ipairs(args) do args[i] = tostring(v) end return WriteFile(true, LocalPlayer.Name.."'s strat", "StrategiesX/TDS/Recorder", table.concat(args, " ").."\n") end local function appendstrat(...) local args = {...} for i,v in ipairs(args) do args[i] = tostring(v) end return AppendFile(true, LocalPlayer.Name.."'s strat", "StrategiesX/TDS/Recorder", table.concat(args, " ").."\n") end

getgenv().Recorder = { Troops = { Golden = {} }, TowersList = {}, SecondMili = 0 } getgenv().TowersList = Recorder.TowersList

function ConvertTimer(num) return math.floor(num/60), num % 60 end

local TimerCheck = false function CheckTimer(bool) return (bool and TimerCheck) or true end

RSTimer.Changed:Connect(function(time) TimerCheck = (time == 5) and true or false end) RSTimer.Changed:Connect(function() Recorder.SecondMili = 0 for _ = 1,9 do task.wait(0.09) Recorder.SecondMili += 0.1 end end)

function GetTimer() local min, sec = ConvertTimer(RSTimer.Value) return {tonumber(GameWave.Text), min, sec + Recorder.SecondMili, tostring(TimerCheck)} end

local TowerCount = 0 local GetMode

local function SetStatus(_) end -- GUI removed

-- Recorder logic (Place/Upgrade/Sell/Target/Ability/Option/Skip/Vote) -- Same as before (omitted here for brevity), can be reused from original -- Ensure you re-include GenerateFunction block if needed without GUI or UILibrary references

for TowerName, Tower in next, ReplicatedStorage.RemoteFunction:InvokeServer("Session", "Search", "Inventory.Troops") do if Tower.Equipped then table.insert(Recorder.Troops, TowerName) if Tower.GoldenPerks then table.insert(Recorder.Troops.Golden, TowerName) end end end

writestrat("getgenv().StratCreditsAuthor = "Optional"") appendstrat("local TDS = loadstring(game:HttpGet("https://raw.githubusercontent.com/TDSX1/Strategies-X/main/TDS/MainSource.lua", true))()\nTDS:Map("" .. RSMap.Value .. "", true, "" .. RSMode.Value .. "")\nTDS:Loadout({"" .. table.concat(Recorder.Troops, '", "') .. ( (#Recorder.Troops.Golden ~= 0 and "", ["Golden"] = {"" .. table.concat(Recorder.Troops.Golden, '", "') .. ""}})" or ""})"))

 local DiffTable = { Easy = "Easy", Casual = "Casual", Intermediate = "Intermediate", Molten = "Molten", Fallen = "Fallen" } task.spawn(function() repeat task.wait() until GetMode or RSDifficulty.Value ~= "" local diff = GetMode or DiffTable[RSDifficulty.Value] if diff then appendstrat("TDS:Mode(""..diff.."")") end end)

 local OldNamecall OldNamecall = hookmetamethod(game, '__namecall', function(...) local self, args = (...), ({select(2, ...)}) if getnamecallmethod() == "InvokeServer" and self.Name == "RemoteFunction" then local thread = coroutine.running() coroutine.wrap(function() local timer = GetTimer() local result = self.InvokeServer(self, unpack(args)) if GenerateFunction[args[2]] then GenerateFunction[args[2]](args, timer, result) end coroutine.resume(thread, result) end)() return coroutine.yield() end return OldNamecall(...) end)

