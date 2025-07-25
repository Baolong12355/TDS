local MacroRecorder = {
    _originalNamecall = nil,
    _enabled = false,
    _eventHandlers = {},
    _fileWriteEnabled = true, -- Bật/tắt ghi file
    _logFile = "macros_log.txt" -- Tên file log
}

-- Khởi tạo hệ thống ghi file
function MacroRecorder:_initFileSystem()
    if not writefile then
        warn("Hệ thống file không khả dụng (có thể đang chạy trong môi trường không hỗ trợ)")
        self._fileWriteEnabled = false
        return
    end
    
    if not isfolder("MacroScripts") then
        makefolder("MacroScripts")
    end
end

-- Ghi dữ liệu vào file
function MacroRecorder:_writeToFile(content)
    if not self._fileWriteEnabled then return end
    
    local success, err = pcall(function()
        local filePath = "MacroScripts/" .. self._logFile
        if not isfile(filePath) then
            writefile(filePath, "-- Macro Script Log --\n\n")
        end
        appendfile(filePath, content .. "\n")
    end)
    
    if not success then
        warn("Lỗi khi ghi file:", err)
    end
end

-- Hook chính
function MacroRecorder:Start()
    if self._enabled then return end
    
    self:_initFileSystem()
    
    self._originalNamecall = hookmetamethod(game, '__namecall', function(...)
        local selfObj, args = (...), ({select(2, ...)})
        local method = getnamecallmethod()
        
        -- Xử lý RemoteFunction
        if method == "InvokeServer" and selfObj.Name == "RemoteFunction" then
            local actionType = args[1]
            local actionData = args[2]
            
            -- Xử lý đặt tháp
            if actionType == "Troops" and actionData == "Place" then
                local troopName = args[3]
                local position = args[4].Position
                local rotation = args[4].Rotation
                local rotX, rotY, rotZ = rotation:ToEulerAnglesYXZ()
                
                local logStr = string.format(
                    'Place("%s", %.2f, %.2f, %.2f, %.2f, %.2f, %.2f)',
                    troopName, position.X, position.Y, position.Z, rotX, rotY, rotZ
                )
                self:_writeToFile(logStr)
                print("[MACRO] " .. logStr)
            
            -- Xử lý nâng cấp tháp
            elseif actionType == "Troops" and actionData == "Upgrade" then
                local troopId = args[4].Troop.Name
                local path = args[4].Path
                
                local logStr = string.format(
                    'Upgrade(%s, %d)',
                    troopId, path
                )
                self:_writeToFile(logStr)
                print("[MACRO] " .. logStr)
            
            -- Xử lý bán tháp
            elseif actionType == "Troops" and actionData == "Sell" then
                local troopId = args[3].Troop.Name
                
                local logStr = string.format(
                    'Sell(%s)',
                    troopId
                )
                self:_writeToFile(logStr)
                print("[MACRO] " .. logStr)
            
            -- Xử lý skip wave
            elseif actionType == "Voting" and actionData == "Skip" then
                local logStr = 'Skip()'
                self:_writeToFile(logStr)
                print("[MACRO] " .. logStr)
            end
        end
        
        return self._originalNamecall(...)
    end)
    
    self._enabled = true
    print("Macro Recorder: Đã bật hook và ghi file")
end

-- Tắt hook
function MacroRecorder:Stop()
    if not self._enabled then return end
    
    if self._originalNamecall then
        hookmetamethod(game, '__namecall', self._originalNamecall)
    end
    
    self._enabled = false
    print("Macro Recorder: Đã tắt hook")
end

-- Đặt tên file log
function MacroRecorder:SetLogFileName(filename)
    self._logFile = filename .. ".txt"
end

-- Bật/tắt ghi file
function MacroRecorder:SetFileWriting(enabled)
    self._fileWriteEnabled = enabled
    print("Ghi file:", enabled and "BẬT" or "TẮT")
end

return MacroRecorder
