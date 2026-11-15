-- ============================================
-- Violence District Game Scanner v4.0
-- Using Obsidian UI Library (proven compatible)
-- ============================================

print("[Scanner] Loading Obsidian UI...")

-- Load Obsidian Library
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

if not Library then
    error("[Scanner] Failed to load Obsidian UI")
    return
end

print("[Scanner] Obsidian UI loaded successfully!")

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
        Team = ""
    }
    
    -- Platform
    results.Platform.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    results.Platform.Touch = UserInputService.TouchEnabled
    results.Platform.Keyboard = UserInputService.KeyboardEnabled
    
    -- Mobile Buttons
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in pairs(playerGui:GetChildren()) do
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                        table.insert(results.Buttons, {
                            Name = obj.Name,
                            Text = obj:IsA("TextButton") and obj.Text or "ImageButton",
                            Parent = obj.Parent.Name,
                            Path = obj:GetFullName()
                        })
                    end
                end
            end
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
                results.Character.JumpPower = hum.JumpPower or hum.JumpHeight
            end
            
            -- Attributes
            results.Character.Attributes = {}
            local attrList = {"speedboost", "IsHooked", "Carried", "Knocked"}
            for _, attr in ipairs(attrList) do
                local val = char:GetAttribute(attr)
                if val ~= nil then
                    results.Character.Attributes[attr] = val
                end
            end
        end
    end)
    
    -- Map Objects
    pcall(function()
        local map = workspace:FindFirstChild("Map")
        if map then
            local counts = {
                Generator = 0,
                Window = 0,
                Palletwrong = 0,
                PalletAlien = 0,
                Hook = 0,
                Gate = 0
            }
            
            for _, obj in pairs(map:GetDescendants()) do
                if counts[obj.Name] ~= nil then
                    counts[obj.Name] = counts[obj.Name] + 1
                end
            end
            
            results.Map = counts
        end
    end)
    
    -- Remotes
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            for _, remote in pairs(remotes:GetDescendants()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    table.insert(results.Remotes, {
                        Name = remote.Name,
                        Type = remote.ClassName,
                        Path = remote:GetFullName()
                    })
                end
            end
        end
    end)
    
    -- Team
    results.Team = LocalPlayer.Team and LocalPlayer.Team.Name or "Unknown"
    
    -- Players
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
    
    -- Platform
    table.insert(lines, "📱 PLATFORM:")
    table.insert(lines, "  Type: " .. (data.Platform.IsMobile and "MOBILE" or "PC"))
    table.insert(lines, "  Touch: " .. tostring(data.Platform.Touch))
    table.insert(lines, "  Keyboard: " .. tostring(data.Platform.Keyboard))
    table.insert(lines, "")
    
    -- Buttons
    if #data.Buttons > 0 then
        table.insert(lines, "🎮 MOBILE BUTTONS (" .. #data.Buttons .. " found):")
        for i = 1, math.min(15, #data.Buttons) do
            local btn = data.Buttons[i]
            table.insert(lines, string.format("  [%d] %s: '%s' (Parent: %s)", 
                i, btn.Name, btn.Text, btn.Parent))
        end
        if #data.Buttons > 15 then
            table.insert(lines, "  ... +" .. (#data.Buttons - 15) .. " more buttons")
        end
        table.insert(lines, "")
    end
    
    -- Character
    if next(data.Character) then
        table.insert(lines, "🧍 CHARACTER:")
        if data.Character.WalkSpeed then
            table.insert(lines, "  WalkSpeed: " .. data.Character.WalkSpeed)
            table.insert(lines, "  Health: " .. data.Character.Health .. "/" .. data.Character.MaxHealth)
        end
        if next(data.Character.Attributes) then
            table.insert(lines, "  Attributes:")
            for attr, val in pairs(data.Character.Attributes) do
                table.insert(lines, "    " .. attr .. " = " .. tostring(val))
            end
        end
        table.insert(lines, "")
    end
    
    -- Map
    if next(data.Map) then
        table.insert(lines, "🗺️ MAP OBJECTS:")
        for objType, count in pairs(data.Map) do
            if count > 0 then
                table.insert(lines, "  " .. objType .. ": " .. count)
            end
        end
        table.insert(lines, "")
    end
    
    -- Remotes
    if #data.Remotes > 0 then
        table.insert(lines, "📡 REMOTES (" .. #data.Remotes .. " found):")
        for i = 1, math.min(12, #data.Remotes) do
            local remote = data.Remotes[i]
            table.insert(lines, "  " .. remote.Name .. " (" .. remote.Type .. ")")
        end
        if #data.Remotes > 12 then
            table.insert(lines, "  ... +" .. (#data.Remotes - 12) .. " more")
        end
        table.insert(lines, "")
    end
    
    -- Team & Players
    table.insert(lines, "👥 SESSION:")
    table.insert(lines, "  Your Team: " .. data.Team)
    table.insert(lines, "  Players: " .. data.PlayerCount)
    table.insert(lines, "")
    
    table.insert(lines, "═══════════════════════════════════════════")
    table.insert(lines, "✅ SCAN COMPLETE")
    table.insert(lines, "═══════════════════════════════════════════")
    
    return table.concat(lines, "\n")
end

-- ════════════════════════════════════════
-- CREATE UI WITH OBSIDIAN
-- ════════════════════════════════════════

local Window = Library:CreateWindow({
    Title = "VD Game Scanner",
    Footer = "Violence District Scanner v4.0",
    NotifySide = "Right",
    ShowCustomCursor = true
})

-- Main Tab
local MainTab = Window:AddTab("Scanner", "search")

-- Info Section
local InfoBox = MainTab:AddLeftGroupbox("Information", "info")

InfoBox:AddLabel("Violence District Game Scanner"):AddColorPicker("LabelColor", {
    Default = Color3.new(0.5, 0.8, 1),
    Title = "Label Color"
})

InfoBox:AddDivider()

InfoBox:AddLabel("Features:"):AddLabel("• Scan game structure"):AddLabel("• Detect mobile buttons"):AddLabel("• Map objects detection"):AddLabel("• Remote events listing"):AddLabel("• Copy to clipboard")

InfoBox:AddDivider()

InfoBox:AddLabel("Platform: " .. (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and "MOBILE" or "PC"))

-- Actions Section
local ActionsBox = MainTab:AddRightGroupbox("Actions", "cpu")

ActionsBox:AddLabel("Scan the game to analyze its structure")

ActionsBox:AddDivider()

local ScanButton = ActionsBox:AddButton("🔍 Start Scan", function()
    Library:Notify({
        Title = "Scanner",
        Description = "Scanning game structure...",
        Duration = 2
    })
    
    task.wait(0.5)
    
    ScanResults = ScanAll()
    
    -- Update Results display
    ResultsBox:Clear()
    
    local formatted = FormatResults(ScanResults)
    for line in formatted:gmatch("[^\n]+") do
        ResultsBox:AddLabel(line)
    end
    
    Library:Notify({
        Title = "Scanner",
        Description = "Scan complete! ✅",
        Duration = 3
    })
end)

ActionsBox:AddDivider()

local CopyButton = ActionsBox:AddButton("📋 Copy Results", function()
    if not ScanResults.Timestamp then
        Library:Notify({
            Title = "Scanner",
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
            Title = "Scanner",
            Description = "Results copied to clipboard!",
            Duration = 3
        })
    else
        Library:Notify({
            Title = "Scanner",
            Description = "Clipboard not supported. Check console.",
            Duration = 3
        })
        print("\n" .. formatted .. "\n")
    end
end)

ActionsBox:AddDivider()

ActionsBox:AddButton("📄 Print to Console", function()
    if not ScanResults.Timestamp then
        Library:Notify({
            Title = "Scanner",
            Description = "Please scan first!",
            Duration = 2
        })
        return
    end
    
    local formatted = FormatResults(ScanResults)
    print("\n" .. formatted .. "\n")
    
    Library:Notify({
        Title = "Scanner",
        Description = "Results printed to console!",
        Duration = 2
    })
end)

-- Results Tab
local ResultsTab = Window:AddTab("Results", "file-text")

local ResultsBox = ResultsTab:AddLeftGroupbox("Scan Results", "list")

ResultsBox:AddLabel("Click 'Start Scan' to begin")
ResultsBox:AddLabel(" ")
ResultsBox:AddLabel("Results will appear here after scanning")

-- Quick Actions in Results Tab
local QuickActionsBox = ResultsTab:AddRightGroupbox("Quick Actions", "zap")

QuickActionsBox:AddButton("🔄 Refresh Results", function()
    if not ScanResults.Timestamp then
        Library:Notify({
            Title = "Scanner",
            Description = "No scan data available",
            Duration = 2
        })
        return
    end
    
    ResultsBox:Clear()
    local formatted = FormatResults(ScanResults)
    for line in formatted:gmatch("[^\n]+") do
        ResultsBox:AddLabel(line)
    end
    
    Library:Notify({
        Title = "Scanner", 
        Description = "Results refreshed!",
        Duration = 2
    })
end)

QuickActionsBox:AddButton("🗑️ Clear Results", function()
    ResultsBox:Clear()
    ResultsBox:AddLabel("Results cleared")
    
    Library:Notify({
        Title = "Scanner",
        Description = "Results cleared",
        Duration = 2
    })
end)

-- Auto-scan on load
task.spawn(function()
    task.wait(2)
    
    Library:Notify({
        Title = "Scanner Ready",
        Description = "Click 'Scan Game' to analyze Violence District",
        Duration = 4
    })
end)

-- Settings Tab
local SettingsTab = Window:AddTab("Settings", "settings")

local ThemeBox = SettingsTab:AddLeftGroupbox("Appearance", "palette")

ThemeBox:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(value)
        Library.ShowCustomCursor = value
    end
})

ThemeBox:AddDropdown("NotificationSide", {
    Values = {"Left", "Right"},
    Default = "Right",
    Text = "Notification Side",
    Callback = function(value)
        Library:SetNotifySide(value)
    end
})

-- Add menu keybind section
local MenuGroup = SettingsTab:AddRightGroupbox("Menu", "wrench")
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

Library.ToggleKeybind = Library.Options.MenuKeybind

print("════════════════════════════════════════")
print("✅ VD Game Scanner v4.0 Loaded!")
print("📱 Using Obsidian UI Library")
print("🔑 Toggle Key: Right Shift")
print("════════════════════════════════════════")

Library:Notify({
    Title = "Scanner Loaded",
    Description = "Welcome to VD Game Scanner v4.0!",
    Duration = 3
})
