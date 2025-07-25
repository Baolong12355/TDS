-- Macro Recorder for TDS (Tower Defense Simulator)
-- Designed for executors (Synapse/Krnl/Script-Ware)
-- Auto-starts recording when injected

local MacroRecorder = {
    Enabled = true,
    LogFolder = "TDS_Macros",
    LogFile = "macro_"..os.date("%Y%m%d_%H%M%S")..".txt",
    RecordPlacements = true,
    RecordUpgrades = true,
    RecordSales = true,
    RecordSkips = true,
    RecordAbilities = true
}

-- Initialize file system
function MacroRecorder:InitFileSystem()
    if not writefile or not makefolder then 
        warn("File functions not available in this executor")
        return false
    end
    
    if not isfolder(self.LogFolder) then
        makefolder(self.LogFolder)
    end
    
    local header = "-- TDS Macro Recording --\n"
    header = header.."-- Generated: "..os.date("%c").."\n"
    header = header.."-- Map: "..game:GetService("ReplicatedStorage").State.Map.Value.."\n"
    header = header.."-- Mode: "..game:GetService("ReplicatedStorage").State.Mode.Value.."\n"
    header = header.."-- Difficulty: "..game:GetService("ReplicatedStorage").State.Difficulty.Value.."\n\n"
    
    writefile(self.LogFolder.."/"..self.LogFile, header)
    return true
end

-- Write to log file
function MacroRecorder:LogAction(command)
    if not self.Enabled then return end
    
    appendfile(self.LogFolder.."/"..self.LogFile, command.."\n")
    print("[MACRO] "..command)
end

-- Main hook function
function MacroRecorder:HookGame()
    local originalNamecall
    originalNamecall = hookmetamethod(game, '__namecall', function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if method == "InvokeServer" and self.Name == "RemoteFunction" then
            local actionType = args[1]
            local actionData = args[2]
            
            -- Place Troop
            if self.RecordPlacements and actionType == "Troops" and actionData == "Place" then
                local troopName = args[3]
                local position = args[4].Position
                local rotation = args[4].Rotation
                local rotX, rotY, rotZ = rotation:ToEulerAnglesYXZ()
                
                self:LogAction(string.format(
                    'TDS:Place("%s", %.2f, %.2f, %.2f, %.2f, %.2f, %.2f)',
                    troopName, position.X, position.Y, position.Z, rotX, rotY, rotZ
                ))
            
            -- Upgrade Troop
            elseif self.RecordUpgrades and actionType == "Troops" and actionData == "Upgrade" then
                local troopId = args[4].Troop.Name
                local path = args[4].Path
                
                self:LogAction(string.format(
                    'TDS:Upgrade(%s, %d)',
                    troopId, path
                ))
            
            -- Sell Troop
            elseif self.RecordSales and actionType == "Troops" and actionData == "Sell" then
                local troopId = args[3].Troop.Name
                self:LogAction(string.format('TDS:Sell(%s)', troopId))
            
            -- Skip Wave
            elseif self.RecordSkips and actionType == "Voting" and actionData == "Skip" then
                self:LogAction('TDS:Skip()')
            end
        end
        
        return originalNamecall(self, ...)
    end)
end

-- Auto-start function
function MacroRecorder:Start()
    if not self:InitFileSystem() then
        warn("Failed to initialize macro recording")
        return
    end
    
    self:HookGame()
    print(string.format(
        "Macro Recorder started\nRecording to: %s/%s",
        self.LogFolder, self.LogFile
    ))
end

-- UI Toggle (optional)
function MacroRecorder:CreateToggleUI()
    local Players = game:GetService("Players")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MacroRecorderUI"
    ScreenGui.Parent = PlayerGui
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 200, 0, 60)
    Frame.Position = UDim2.new(0, 10, 0, 10)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Parent = ScreenGui
    
    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0.9, 0, 0.6, 0)
    Toggle.Position = UDim2.new(0.05, 0, 0.2, 0)
    Toggle.Text = "Macro Recorder: ON"
    Toggle.TextColor3 = Color3.fromRGB(0, 255, 0)
    Toggle.Parent = Frame
    
    Toggle.MouseButton1Click:function()
        self.Enabled = not self.Enabled
        Toggle.Text = "Macro Recorder: "..(self.Enabled and "ON" or "OFF")
        Toggle.TextColor3 = self.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
end

-- Auto-start when script runs
MacroRecorder:Start()

-- Optional: Uncomment to add toggle UI
-- MacroRecorder:CreateToggleUI()

return MacroRecorder