-- ============================================
-- Violence District Game Scanner v3.0
-- Ultra-simplified for maximum compatibility
-- ============================================

print("[Scanner] Loading...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ════════════════════════════════════════
-- SCAN FUNCTIONS (Same as SimpleScan)
-- ════════════════════════════════════════

local function ScanAll()
    local results = {}
    
    -- Input System
    results.Platform = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and "MOBILE" or "PC"
    results.Touch = UserInputService.TouchEnabled
    results.Keyboard = UserInputService.KeyboardEnabled
    
    -- Mobile Buttons
    results.Buttons = {}
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
    results.Character = {}
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
    results.Map = {}
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
    results.Remotes = {}
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            for _, remote in pairs(remotes:GetDescendants()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    table.insert(results.Remotes, remote.Name .. " (" .. remote.ClassName .. ")")
                end
            end
        end
    end)
    
    -- Team
    results.Team = LocalPlayer.Team and LocalPlayer.Team.Name or "Unknown"
    
    return results
end

-- ════════════════════════════════════════
-- CREATE MINIMAL GUI
-- ════════════════════════════════════════

local function CreateGUI()
    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "VD_Scanner"
    sg.ResetOnSpawn = false
    
    pcall(function()
        sg.Parent = LocalPlayer.PlayerGui
    end)
    
    if not sg.Parent then
        warn("[Scanner] Can't create GUI")
        return nil
    end
    
    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 400, 0, 500)
    main.Position = UDim2.new(0.5, -200, 0.5, -250)
    main.BackgroundColor3 = Color3.new(0.1, 0.1, 0.12)
    main.BorderSizePixel = 1
    main.BorderColor3 = Color3.new(0.3, 0.3, 0.35)
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 30)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "VD Game Scanner"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 14
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main
    
    -- Close Button
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    close.Text = "X"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.TextSize = 12
    close.Font = Enum.Font.SourceSansBold
    close.Parent = main
    
    close.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)
    
    -- Results Frame (scrollable)
    local results = Instance.new("ScrollingFrame")
    results.Size = UDim2.new(1, -10, 1, -90)
    results.Position = UDim2.new(0, 5, 0, 40)
    results.BackgroundColor3 = Color3.new(0.05, 0.05, 0.07)
    results.BorderSizePixel = 0
    results.ScrollBarThickness = 6
    results.CanvasSize = UDim2.new(0, 0, 0, 0)
    results.Parent = main
    
    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = results
    
    -- Update canvas size on layout change
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        results.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -10, 0, 20)
    status.Position = UDim2.new(0, 5, 1, -45)
    status.BackgroundTransparency = 1
    status.Text = "Ready"
    status.TextColor3 = Color3.new(0.5, 1, 0.5)
    status.TextSize = 10
    status.Font = Enum.Font.SourceSans
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = main
    
    -- Scan Button
    local scan = Instance.new("TextButton")
    scan.Size = UDim2.new(0.48, 0, 0, 25)
    scan.Position = UDim2.new(0, 5, 1, -25)
    scan.BackgroundColor3 = Color3.new(0.2, 0.5, 0.8)
    scan.Text = "Scan"
    scan.TextColor3 = Color3.new(1, 1, 1)
    scan.TextSize = 12
    scan.Font = Enum.Font.SourceSansBold
    scan.Parent = main
    
    -- Copy Button
    local copy = Instance.new("TextButton")
    copy.Size = UDim2.new(0.48, 0, 0, 25)
    copy.Position = UDim2.new(0.52, 0, 1, -25)
    copy.BackgroundColor3 = Color3.new(0.2, 0.7, 0.4)
    copy.Text = "Copy"
    copy.TextColor3 = Color3.new(1, 1, 1)
    copy.TextSize = 12
    copy.Font = Enum.Font.SourceSansBold
    copy.Parent = main
    
    return {
        ScreenGui = sg,
        Main = main,
        Results = results,
        Status = status,
        ScanBtn = scan,
        CopyBtn = copy
    }
end

-- ════════════════════════════════════════
-- DISPLAY RESULTS
-- ════════════════════════════════════════

local function AddLine(parent, text, color)
    local line = Instance.new("TextLabel")
    line.Size = UDim2.new(1, -10, 0, 0)
    line.BackgroundTransparency = 1
    line.Text = text
    line.TextColor3 = color or Color3.new(0.9, 0.9, 0.9)
    line.TextSize = 9
    line.Font = Enum.Font.Code
    line.TextXAlignment = Enum.TextXAlignment.Left
    line.TextYAlignment = Enum.TextYAlignment.Top
    line.TextWrapped = true
    line.Parent = parent
    
    -- Auto-size after adding
    task.wait()
    local textBounds = game:GetService("TextService"):GetTextSize(
        text, 9, Enum.Font.Code, Vector2.new(parent.AbsoluteSize.X - 10, 10000)
    )
    line.Size = UDim2.new(1, -10, 0, textBounds.Y)
    
    return line
end

local lastScanData = nil

local function DisplayResults(ui, data)
    -- Clear old results
    for _, child in pairs(ui.Results:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    lastScanData = data
    
    -- Display
    AddLine(ui.Results, "=" .. string.rep("=", 38), Color3.new(0.5, 0.7, 1))
    AddLine(ui.Results, "VIOLENCE DISTRICT - SCAN RESULTS", Color3.new(0.5, 1, 1))
    AddLine(ui.Results, "Time: " .. os.date("%H:%M:%S"), Color3.new(0.6, 0.6, 0.6))
    AddLine(ui.Results, "=" .. string.rep("=", 38), Color3.new(0.5, 0.7, 1))
    AddLine(ui.Results, "")
    
    -- Platform
    AddLine(ui.Results, "PLATFORM:", Color3.new(1, 0.8, 0.4))
    AddLine(ui.Results, "  Type: " .. data.Platform)
    AddLine(ui.Results, "  Touch: " .. tostring(data.Touch))
    AddLine(ui.Results, "")
    
    -- Buttons
    if #data.Buttons > 0 then
        AddLine(ui.Results, "BUTTONS (" .. #data.Buttons .. "):", Color3.new(0.5, 1, 0.5))
        for i = 1, math.min(10, #data.Buttons) do
            local btn = data.Buttons[i]
            AddLine(ui.Results, string.format("  [%d] %s: '%s'", i, btn.Name, btn.Text))
        end
        if #data.Buttons > 10 then
            AddLine(ui.Results, "  ... +" .. (#data.Buttons - 10) .. " more")
        end
        AddLine(ui.Results, "")
    end
    
    -- Character
    if data.Character.WalkSpeed then
        AddLine(ui.Results, "CHARACTER:", Color3.new(1, 0.7, 0.5))
        AddLine(ui.Results, "  Speed: " .. data.Character.WalkSpeed)
        AddLine(ui.Results, "  HP: " .. data.Character.Health .. "/" .. data.Character.MaxHealth)
        AddLine(ui.Results, "")
    end
    
    -- Map
    if next(data.Map) then
        AddLine(ui.Results, "MAP OBJECTS:", Color3.new(0.7, 1, 0.7))
        for name, count in pairs(data.Map) do
            if count > 0 then
                AddLine(ui.Results, "  " .. name .. ": " .. count)
            end
        end
        AddLine(ui.Results, "")
    end
    
    -- Remotes
    if #data.Remotes > 0 then
        AddLine(ui.Results, "REMOTES (" .. #data.Remotes .. "):", Color3.new(1, 0.8, 0.7))
        for i = 1, math.min(8, #data.Remotes) do
            AddLine(ui.Results, "  " .. data.Remotes[i])
        end
        if #data.Remotes > 8 then
            AddLine(ui.Results, "  ... +" .. (#data.Remotes - 8) .. " more")
        end
        AddLine(ui.Results, "")
    end
    
    -- Team
    AddLine(ui.Results, "TEAM: " .. data.Team, Color3.new(0.8, 0.8, 1))
    
    AddLine(ui.Results, "")
    AddLine(ui.Results, "=" .. string.rep("=", 38), Color3.new(0.5, 0.7, 1))
end

-- ════════════════════════════════════════
-- INITIALIZE
-- ════════════════════════════════════════

local ui = CreateGUI()

if not ui then
    error("[Scanner] Failed to create GUI")
    return
end

-- Scan button
ui.ScanBtn.MouseButton1Click:Connect(function()
    ui.Status.Text = "Scanning..."
    ui.Status.TextColor3 = Color3.new(1, 0.8, 0.3)
    
    task.wait(0.2)
    
    local data = ScanAll()
    DisplayResults(ui, data)
    
    ui.Status.Text = "Scan complete!"
    ui.Status.TextColor3 = Color3.new(0.5, 1, 0.5)
end)

-- Copy button
ui.CopyBtn.MouseButton1Click:Connect(function()
    if not lastScanData then
        ui.Status.Text = "Scan first!"
        ui.Status.TextColor3 = Color3.new(1, 0.3, 0.3)
        return
    end
    
    -- Build text output
    local output = {}
    table.insert(output, "=== VD SCAN RESULTS ===")
    table.insert(output, "Platform: " .. lastScanData.Platform)
    table.insert(output, "Buttons: " .. #lastScanData.Buttons)
    table.insert(output, "Team: " .. lastScanData.Team)
    
    local text = table.concat(output, "\n")
    
    local ok = pcall(function()
        setclipboard(text)
    end)
    
    if ok then
        ui.Status.Text = "Copied!"
        ui.Status.TextColor3 = Color3.new(0.5, 1, 0.5)
    else
        ui.Status.Text = "Copy failed (see console)"
        ui.Status.TextColor3 = Color3.new(1, 0.8, 0.3)
        print(text)
    end
end)

print("[Scanner] GUI loaded! Click 'Scan' button")
