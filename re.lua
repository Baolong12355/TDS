-- TDS Recorder Macros Module
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- File handling functions
getgenv().WriteFile = function(check, name, location, str)
    if not check then
        return
    end
    if type(name) == "string" then
        if not type(location) == "string" then
            location = ""
        end
        if not isfolder(location) then
            makefolder(location)
        end
        if type(str) ~= "string" then
            error("Argument 4 must be a string got " .. tostring(str))
        end
        writefile(location.."/"..name..".txt", str)
    else
        error("Argument 2 must be a string got " .. tostring(name))
    end
end

getgenv().AppendFile = function(check, name, location, str)
    if not check then
        return
    end
    if type(name) == "string" then
        if not type(location) == "string" then
            location = ""
        end
        if not isfolder(location) then
            WriteFile(check, name, location, str)
        end
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
local writestrat = function(...)
    local TableText = {...}
    task.spawn(function()
        if not game:GetService("Players").LocalPlayer then
            repeat task.wait() until game:GetService("Players").LocalPlayer
        end
        for i, v in next, TableText do
            if type(v) ~= "string" then
                TableText[i] = tostring(v)
            end
        end
        local Text = table.concat(TableText, " ")
        print(Text)
        return WriteFile(true, LocalPlayer.Name.."'s strat", "StrategiesX/TDS/Recorder", tostring(Text).."\n")
    end)
end

local appendstrat = function(...)
    local TableText = {...}
    task.spawn(function()
        if not game:GetService("Players").LocalPlayer then
            repeat task.wait() until game:GetService("Players").LocalPlayer
        end
        for i, v in next, TableText do
            if type(v) ~= "string" then
                TableText[i] = tostring(v)
            end
        end
        local Text = table.concat(TableText, " ")
        print(Text)
        return AppendFile(true, LocalPlayer.Name.."'s strat", "StrategiesX/TDS/Recorder", tostring(Text).."\n")
    end)
end

-- Recording functions that generate macro commands
local GenerateFunction = {
    Place = function(Args, Timer, RemoteCheck)
        if typeof(RemoteCheck) ~= "Instance" then
            return
        end
        local TowerName = Args[3]
        local Position = Args[4].Position
        local Rotation = Args[4].Rotation
        local RotateX, RotateY, RotateZ = Rotation:ToEulerAnglesYXZ()
        
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Place("{TowerName}", {Position.X}, {Position.Y}, {Position.Z}, {TimerStr}, {RotateX}, {RotateY}, {RotateZ})`)
    end,
    
    Upgrade = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local PathTarget = Args[4].Path
        if RemoteCheck ~= true then
            return
        end
        
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Upgrade({TowerIndex}, {TimerStr}, {PathTarget})`)
    end,
    
    Sell = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[3].Troop.Name
        if not RemoteCheck then
            return
        end
        
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Sell({TowerIndex}, {TimerStr})`)
    end,
    
    Target = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local Target = Args[4].Target
        if RemoteCheck ~= true then
            return
        end
        
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Target({TowerIndex}, "{Target}", {TimerStr})`)
    end,
    
    Abilities = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local AbilityName = Args[4].Name
        local Data = Args[4].Data
        if RemoteCheck ~= true then
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
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Ability({TowerIndex}, "{AbilityName}", {TimerStr}, {formattedData})`)
    end,
    
    Option = function(Args, Timer, RemoteCheck)
        local TowerIndex = Args[4].Troop.Name
        local OptionName = Args[4].Name
        local Value = Args[4].Value
        if RemoteCheck ~= true then
            return
        end
        
        local TimerStr = table.concat(Timer, ", ")
        appendstrat(`TDS:Option({TowerIndex}, "{OptionName}", "{Value}", {TimerStr})`)
    end,
    
    Skip = function(Args, Timer, RemoteCheck)
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
        local GetMode = DiffTable[Difficulty] or Difficulty
        -- Vote function doesn't write to strategy file, just processes the vote
    end,
}

-- Export functions for external use
return {
    WriteFile = WriteFile,
    AppendFile = AppendFile,
    writestrat = writestrat,
    appendstrat = appendstrat,
    GenerateFunction = GenerateFunction
}