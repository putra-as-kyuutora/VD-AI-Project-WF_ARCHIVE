-- ============================================
-- Violence District Game Scanner v4.1
-- With Save to File Feature
-- ============================================

print("[Scanner] Loading Obsidian UI...")

-- Load Obsidian Library
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

if not Library then
    error("[Scanner] Failed to load Obsidian UI")
    return
end

print("[Scanner] Obsidian UI loaded!")

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Storage
local ScanResults = {}

-- ════════════════════════════════════════
-- SCAN FUNCTIONS
-- ════════════════════════════════════════

local function ScanAll()
    local results = {
        Timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        Platform = {},
        Buttons = {},
        Character = {},
        Map = {},
        Remotes = {},
        Team = "",
        PlayerCount = 0
    }
    
    -- Platform
    results.Platform.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    results.Platform.Touch = UserInputService.TouchEnabled
    results.Platform.Keyboard = UserInputService.KeyboardEnabled
    
    -- Mobile Buttons (FILTER important ones only!)
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local importantButtons = {}
            local seenButtons = {}  -- Avoid duplicates
            
            for _, gui in pairs(playerGui:GetChildren()) do
                for _, obj in pairs(gui:GetDescendants()) do
                    if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                        local buttonName = obj.Name:lower()
                        
                        -- Filter: Only important gameplay buttons
                        local isImportant = 
                            buttonName:find("interact") or
                            buttonName:find("repair") or
                            buttonName:find("heal") or
                            buttonName:find("drop") or
                            buttonName:find("pallet") or
                            buttonName:find("vault") or
                            buttonName:find("gate") or
                            buttonName:find("skill") or
                            buttonName:find("generator") or
                            buttonName:find("action") or
                            buttonName:find("prompt") or
                            (obj:IsA("TextButton") and obj.Text ~= "")
                        
                        if isImportant and not seenButtons[obj.Name] then
                            seenButtons[obj.Name] = true
                            table.insert(importantButtons, {
                                Name = obj.Name,
                                Text = obj:IsA("TextButton") and obj.Text or "ImageButton",
                                Parent = obj.Parent.Name,
                                Position = tostring(obj.Position)
                            })
                        end
                    end
                end
            end
            
            results.Buttons = importantButtons
        end
    end)
    
    -- Character
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                results.Character.WalkSpeed = hum.WalkSpeed
                results.Character.Health = hum.Health
                results.Character.MaxHealth = hum.MaxHealth
            end
        end
    end)
    
    -- Map Objects (ENHANCED - Scan ALL important objects!)
    pcall(function()
        local map = workspace:FindFirstChild("Map")
        if map then
            local objects = {
                Generator = {},
                Window = {},
                Pallet = {},
                Palletwrong = {},
                Hook = {},
                Gate = {},
                ExitGate = {},
                Locker = {},
                Chest = {}
            }
            
            -- Scan all map descendants
            for _, obj in pairs(map:GetDescendants()) do
                local objName = obj.Name
                
                -- Check if it's an important object
                if objects[objName] then
                    local position = nil
                    
                    if obj:IsA("Model") then
                        local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if primaryPart then
                            position = primaryPart.Position
                        end
                    elseif obj:IsA("BasePart") then
                        position = obj.Position
                    end
                    
                    if position then
                        -- Get attributes (for generators)
                        local progress = obj:GetAttribute("RepairProgress") or 
                                       obj:GetAttribute("Progress") or 
                                       obj:GetAttribute("RepairPercent") or 0
                        
                        local powered = obj:GetAttribute("Powered") or 
                                      obj:GetAttribute("IsActive") or false
                        
                        table.insert(objects[objName], {
                            Position = position,
                            Progress = progress,
                            Powered = powered,
                            FullPath = obj:GetFullName()
                        })
                    end
                end
            end
            
            results.Map = objects
        end
    end)
    
    -- Remotes (ENHANCED - Group by type and show more details!)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local categories = {
                Interaction = {},
                Movement = {},
                Generator = {},
                Skill = {},
                Combat = {},
                Other = {}
            }
            
            for _, remote in pairs(remotes:GetDescendants()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    local remoteName = remote.Name:lower()
                    local info = {
                        Name = remote.Name,
                        Type = remote.ClassName,
                        Path = remote:GetFullName()
                    }
                    
                    -- Categorize
                    if remoteName:find("interact") or remoteName:find("prompt") or 
                       remoteName:find("use") or remoteName:find("action") then
                        table.insert(categories.Interaction, info)
                    elseif remoteName:find("vault") or remoteName:find("move") or 
                           remoteName:find("walk") or remoteName:find("sprint") then
                        table.insert(categories.Movement, info)
                    elseif remoteName:find("generator") or remoteName:find("repair") or 
                           remoteName:find("gen") then
                        table.insert(categories.Generator, info)
                    elseif remoteName:find("skill") or remoteName:find("check") then
                        table.insert(categories.Skill, info)
                    elseif remoteName:find("hit") or remoteName:find("attack") or 
                           remoteName:find("damage") or remoteName:find("hook") then
                        table.insert(categories.Combat, info)
                    else
                        table.insert(categories.Other, info)
                    end
                end
            end
            
            results.Remotes = categories
        end
    end)
    
    -- Team
    results.Team = LocalPlayer.Team and LocalPlayer.Team.Name or "Unknown"
    results.PlayerCount = #Players:GetPlayers()
    
    return results
end

local function FormatResults(data)
    local lines = {}
    
    table.insert(lines, "═══════════════════════════════════════════")
    table.insert(lines, "VIOLENCE DISTRICT - GAME SCAN RESULTS")
    table.insert(lines, "Generated: " .. data.Timestamp)
    table.insert(lines, "═══════════════════════════════════════════")
    table.insert(lines, "")
    
    -- Session Info
    table.insert(lines, "👥 SESSION:")
    table.insert(lines, "  Team: " .. data.Team)
    table.insert(lines, "  Players: " .. data.PlayerCount)
    table.insert(lines, "  Platform: " .. (data.Platform.IsMobile and "MOBILE" or "PC"))
    table.insert(lines, "")
    
    -- Character
    if data.Character.WalkSpeed then
        table.insert(lines, "🧍 CHARACTER:")
        table.insert(lines, "  Speed: " .. data.Character.WalkSpeed)
        table.insert(lines, "  HP: " .. data.Character.Health .. "/" .. data.Character.MaxHealth)
        table.insert(lines, "")
    end
    
    -- Buttons
    if #data.Buttons > 0 then
        table.insert(lines, "🎮 IMPORTANT BUTTONS (" .. #data.Buttons .. "):")
        for i = 1, math.min(20, #data.Buttons) do
            local btn = data.Buttons[i]
            table.insert(lines, string.format("  [%d] %s: '%s' (Parent: %s)", 
                i, btn.Name, btn.Text, btn.Parent))
        end
        if #data.Buttons > 20 then
            table.insert(lines, "  ... +" .. (#data.Buttons - 20) .. " more")
        end
        table.insert(lines, "")
    end
    
    -- Map Objects
    if next(data.Map) then
        table.insert(lines, "🗺️ MAP OBJECTS:")
        for objType, objects in pairs(data.Map) do
            if #objects > 0 then
                table.insert(lines, "")
                table.insert(lines, "  📍 " .. objType .. " (" .. #objects .. "):")
                
                for i = 1, math.min(5, #objects) do
                    local obj = objects[i]
                    local pos = obj.Position
                    local extra = ""
                    
                    if obj.Progress > 0 then
                        extra = string.format(" [Progress: %d%%]", math.floor(obj.Progress))
                    elseif obj.Powered then
                        extra = " [POWERED]"
                    end
                    
                    table.insert(lines, string.format("    #%d: (%.0f, %.0f, %.0f)%s", 
                        i, pos.X, pos.Y, pos.Z, extra))
                end
                
                if #objects > 5 then
                    table.insert(lines, "    ... +" .. (#objects - 5) .. " more")
                end
            end
        end
        table.insert(lines, "")
    end
    
    -- Remotes by Category
    if next(data.Remotes) then
        table.insert(lines, "📡 REMOTE EVENTS (By Category):")
        
        local categories = {"Interaction", "Movement", "Generator", "Skill", "Combat", "Other"}
        for _, category in ipairs(categories) do
            local remotes = data.Remotes[category]
            if remotes and #remotes > 0 then
                table.insert(lines, "")
                table.insert(lines, "  🔹 " .. category .. " (" .. #remotes .. "):")
                
                for i = 1, math.min(10, #remotes) do
                    local r = remotes[i]
                    table.insert(lines, "    • " .. r.Name .. " (" .. r.Type .. ")")
                end
                
                if #remotes > 10 then
                    table.insert(lines, "    ... +" .. (#remotes - 10) .. " more")
                end
            end
        end
        table.insert(lines, "")
    end
    
    table.insert(lines, "═══════════════════════════════════════════")
    table.insert(lines, "💡 TIP: Join a game session for full scan!")
    table.insert(lines, "═══════════════════════════════════════════")
    
    return table.concat(lines, "\n")
end

-- ════════════════════════════════════════
-- CREATE UI
-- ════════════════════════════════════════

local Window = Library:CreateWindow({
    Title = "VD Game Scanner",
    Footer = "Violence District v4.1",
    NotifySide = "Right",
    ShowCustomCursor = true
})

-- Main Tab
local MainTab = Window:AddTab("Scanner", "search")

-- Info Box
local InfoBox = MainTab:AddLeftGroupbox("Information", "info")
InfoBox:AddLabel("Violence District Game Scanner")
InfoBox:AddLabel(" ")
InfoBox:AddLabel("Features:")
InfoBox:AddLabel("• Scan game structure")
InfoBox:AddLabel("• Save results to file")
InfoBox:AddLabel("• Copy to clipboard")
InfoBox:AddLabel(" ")
InfoBox:AddLabel("Platform: " .. (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and "MOBILE" or "PC"))

-- Actions Box
local ActionsBox = MainTab:AddRightGroupbox("Actions", "cpu")

ActionsBox:AddButton("🔍 Start Scan", function()
    Library:Notify({
        Title = "Scanner",
        Description = "Scanning...",
        Duration = 2
    })
    
    task.wait(0.3)
    
    ScanResults = ScanAll()
    
    Library:Notify({
        Title = "Scanner",
        Description = "Scan complete! ✅",
        Duration = 3
    })
end)

ActionsBox:AddButton("💾 Save to File", function()
    if not ScanResults.Timestamp then
        Library:Notify({
            Title = "Error",
            Description = "Please scan first!",
            Duration = 2
        })
        return
    end
    
    local formatted = FormatResults(ScanResults)
    local fileName = "VD_Scan_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
    
    local success = pcall(function()
        writefile(fileName, formatted)
    end)
    
    if success then
        Library:Notify({
            Title = "Success",
            Description = "Saved: " .. fileName,
            Duration = 4
        })
    else
        Library:Notify({
            Title = "Error",
            Description = "writefile() not supported",
            Duration = 3
        })
    end
end)

ActionsBox:AddButton("📋 Copy to Clipboard", function()
    if not ScanResults.Timestamp then
        Library:Notify({
            Title = "Error",
            Description = "Please scan first!",
            Duration = 2
        })
        return
    end
    
    local formatted = FormatResults(ScanResults)
    
    local success = pcall(function()
        setclipboard(formatted)
    end)
    
    if success then
        Library:Notify({
            Title = "Success",
            Description = "Copied to clipboard!",
            Duration = 3
        })
    else
        Library:Notify({
            Title = "Info",
            Description = "Printed to console",
            Duration = 2
        })
        print("\n" .. formatted .. "\n")
    end
end)

ActionsBox:AddButton("📄 Print to Console", function()
    if not ScanResults.Timestamp then
        Library:Notify({
            Title = "Error",
            Description = "Please scan first!",
            Duration = 2
        })
        return
    end
    
    local formatted = FormatResults(ScanResults)
    print("\n" .. formatted .. "\n")
    
    Library:Notify({
        Title = "Success",
        Description = "Printed to console",
        Duration = 2
    })
end)

-- Settings Tab
local SettingsTab = Window:AddTab("Settings", "settings")

local ThemeBox = SettingsTab:AddLeftGroupbox("Menu", "palette")

ThemeBox:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu toggle"
})

Library.ToggleKeybind = Library.Options.MenuKeybind

print("════════════════════════════════════════")
print("✅ VD Game Scanner v4.1 Loaded!")
print("🔑 Toggle: Right Shift")
print("════════════════════════════════════════")

Library:Notify({
    Title = "Scanner Ready",
    Description = "Click 'Start Scan' to begin",
    Duration = 3
})
