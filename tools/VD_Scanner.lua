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
                            Parent = obj.Parent.Name
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
            end
        end
    end)
    
    -- Map Objects
    pcall(function()
        local map = workspace:FindFirstChild("Map")
        if map then
            local counts = {Generator = 0, Window = 0, Palletwrong = 0, Hook = 0, Gate = 0}
            
            for _, obj in pairs(map:GetDescendants()) do
                if counts[obj.Name] then
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
                        Type = remote.ClassName
                    })
                end
            end
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
    
    -- Platform
    table.insert(lines, "📱 PLATFORM:")
    table.insert(lines, "  Type: " .. (data.Platform.IsMobile and "MOBILE" or "PC"))
    table.insert(lines, "  Touch: " .. tostring(data.Platform.Touch))
    table.insert(lines, "")
    
    -- Buttons
    if #data.Buttons > 0 then
        table.insert(lines, "🎮 BUTTONS (" .. #data.Buttons .. "):")
        for i = 1, math.min(15, #data.Buttons) do
            local btn = data.Buttons[i]
            table.insert(lines, string.format("  [%d] %s: '%s'", i, btn.Name, btn.Text))
        end
        if #data.Buttons > 15 then
            table.insert(lines, "  ... +" .. (#data.Buttons - 15) .. " more")
        end
        table.insert(lines, "")
    end
    
    -- Character
    if data.Character.WalkSpeed then
        table.insert(lines, "🧍 CHARACTER:")
        table.insert(lines, "  Speed: " .. data.Character.WalkSpeed)
        table.insert(lines, "  HP: " .. data.Character.Health .. "/" .. data.Character.MaxHealth)
        table.insert(lines, "")
    end
    
    -- Map
    if next(data.Map) then
        table.insert(lines, "🗺️ MAP OBJECTS:")
        for name, count in pairs(data.Map) do
            if count > 0 then
                table.insert(lines, "  " .. name .. ": " .. count)
            end
        end
        table.insert(lines, "")
    end
    
    -- Remotes
    if #data.Remotes > 0 then
        table.insert(lines, "📡 REMOTES (" .. #data.Remotes .. "):")
        for i = 1, math.min(10, #data.Remotes) do
            local r = data.Remotes[i]
            table.insert(lines, "  " .. r.Name .. " (" .. r.Type .. ")")
        end
        if #data.Remotes > 10 then
            table.insert(lines, "  ... +" .. (#data.Remotes - 10) .. " more")
        end
        table.insert(lines, "")
    end
    
    -- Session
    table.insert(lines, "👥 SESSION:")
    table.insert(lines, "  Team: " .. data.Team)
    table.insert(lines, "  Players: " .. data.PlayerCount)
    table.insert(lines, "")
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
