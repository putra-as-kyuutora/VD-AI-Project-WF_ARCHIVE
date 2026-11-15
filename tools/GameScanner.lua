-- ============================================
-- Violence District Game Scanner v2.0
-- Scans game structure with proper GUI
-- ============================================

local GameScanner = {
    Version = "2.0.0",
    ScanData = {},
    UI = {}
}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

print("[GameScanner] Loading...")

-- ============================================
-- UI Creation
-- ============================================

-- ════════════════════════════════════════
-- UI CREATION (Simplified & Safe)
-- ════════════════════════════════════════

local function CreateUI()
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VD_GameScannerUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Safe parent
    pcall(function()
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    
    if not ScreenGui.Parent then
        warn("[Scanner] Failed to parent GUI")
        return nil
    end
    
    -- Main Frame (Draggable Window)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 450, 0, 550)
    MainFrame.Position = UDim2.new(0.5, -225, 0.5, -275)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Corner radius
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
    
    -- Title
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "VD Game Scanner"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 25, 0, 25)
    CloseButton.Position = UDim2.new(1, -30, 0.5, -12.5)
    CloseButton.AnchorPoint = Vector2.new(0, 0.5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 12
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.BorderSizePixel = 0
    CloseButton.Parent = TitleBar
    
    Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 5)
    
    CloseButton.MouseButton1Click:Connect(function()
        pcall(function() ScreenGui:Destroy() end)
    end)
    
    -- Content Frame (scrollable)
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -20, 1, -120)
    ContentFrame.Position = UDim2.new(0, 10, 0, 45)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 4
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ContentFrame.Parent = MainFrame
    
    Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 8)
    
    -- Layout for content
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 5)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ContentFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 8)
    Padding.PaddingRight = UDim.new(0, 8)
    Padding.PaddingTop = UDim.new(0, 8)
    Padding.PaddingBottom = UDim.new(0, 8)
    Padding.Parent = ContentFrame
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -20, 0, 25)
    StatusLabel.Position = UDim2.new(0, 10, 1, -70)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Ready to scan"
    StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = MainFrame
    
    -- Button Container
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Size = UDim2.new(1, -20, 0, 35)
    ButtonContainer.Position = UDim2.new(0, 10, 1, -45)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = MainFrame
    
    -- Scan Button
    local ScanButton = Instance.new("TextButton")
    ScanButton.Size = UDim2.new(0.48, 0, 1, 0)
    ScanButton.Position = UDim2.new(0, 0, 0, 0)
    ScanButton.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    ScanButton.Text = "Scan Game"
    ScanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ScanButton.TextSize = 12
    ScanButton.Font = Enum.Font.GothamBold
    ScanButton.BorderSizePixel = 0
    ScanButton.Parent = ButtonContainer
    
    Instance.new("UICorner", ScanButton).CornerRadius = UDim.new(0, 6)
    
    -- Copy Button
    local CopyButton = Instance.new("TextButton")
    CopyButton.Size = UDim2.new(0.48, 0, 1, 0)
    CopyButton.Position = UDim2.new(0.52, 0, 0, 0)
    CopyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 100)
    CopyButton.Text = "Copy Results"
    CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyButton.TextSize = 12
    CopyButton.Font = Enum.Font.GothamBold
    CopyButton.BorderSizePixel = 0
    CopyButton.Parent = ButtonContainer
    
    Instance.new("UICorner", CopyButton).CornerRadius = UDim.new(0, 6)
    
    print("[GameScanner] UI created successfully")
    
    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        ContentFrame = ContentFrame,
        StatusLabel = StatusLabel,
        ScanButton = ScanButton,
        CopyButton = CopyButton
    }
end

-- ============================================
-- Scan Functions
-- ============================================

-- ════════════════════════════════════════
-- DISPLAY FUNCTIONS
-- ════════════════════════════════════════

local function AddResultText(parent, text, color)
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    textLabel.TextSize = 10
    textLabel.Font = Enum.Font.Code
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextWrapped = true
    textLabel.AutomaticSize = Enum.AutomaticSize.Y
    textLabel.Parent = parent
end

-- ════════════════════════════════════════
-- SCAN FUNCTIONS (Safe versions)
-- ════════════════════════════════════════

local function ScanPlayerGUI()
    local data = {
        Found = {},
        Mobile = {}
    }
    
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        -- Scan for SkillCheck GUI
        local skillCheckGui = playerGui:FindFirstChild("SkillCheckPromptGui")
        if skillCheckGui then
            data.Found["SkillCheckPromptGui"] = {
                Path = "PlayerGui.SkillCheckPromptGui",
                Children = {}
            }
            
            for _, child in ipairs(skillCheckGui:GetDescendants()) do
                if child:IsA("GuiObject") then
                    table.insert(data.Found["SkillCheckPromptGui"].Children, child.Name)
                end
            end
        end
        
        -- Scan for Mobile Buttons
        for _, gui in ipairs(playerGui:GetChildren()) do
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local buttonInfo = {
                        Name = obj.Name,
                        Path = obj:GetFullName(),
                        Text = obj:IsA("TextButton") and obj.Text or "ImageButton",
                        Visible = obj.Visible,
                        Parent = obj.Parent.Name
                    }
                    table.insert(data.Mobile, buttonInfo)
                end
            end
        end
    end)
    
    return data
end

local function ScanCharacter()
    local data = {}
    
    local character = LocalPlayer.Character
    if not character then return data end
    
    -- Check for known attributes (based on source code)
    data.Attributes = {}
    local knownAttributes = {
        "speedboost", "IsHooked", "Carried", "Grabbed", 
        "Knocked", "KillerType", "Mask", "SelectedKiller"
    }
    for _, attrName in ipairs(knownAttributes) do
        local value = character:GetAttribute(attrName)
        if value ~= nil then
            data.Attributes[attrName] = value
        end
    end
    
    -- Get humanoid info
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        data.Humanoid = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            Health = humanoid.Health,
            MaxHealth = humanoid.MaxHealth
        }
        
        -- Check humanoid attributes
        data.Humanoid.Attributes = {}
        for _, attrName in ipairs(knownAttributes) do
            local value = humanoid:GetAttribute(attrName)
            if value ~= nil then
                data.Humanoid.Attributes[attrName] = value
            end
        end
    end
    
    -- Get tools
    data.Tools = {}
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(data.Tools, tool.Name)
        end
    end
    
    return data
end

local function ScanRemotes()
    local data = {
        ReplicatedStorage = {},
        Found = {}
    }
    
    -- Scan ReplicatedStorage safely
    safePcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            for _, remote in ipairs(remotes:GetDescendants()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    table.insert(data.ReplicatedStorage, {
                        Name = remote.Name,
                        Type = remote.ClassName,
                        Path = remote:GetFullName()
                    })
                end
            end
        end
    end)
    
    return data
end

local function ScanMap()
    local data = {
        Objects = {},
        Structure = {}
    }
    
    local success, map = pcall(function()
        return workspace:FindFirstChild("Map")
    end)
    
    if not success or not map then 
        warn("[GameScanner] Map not found in workspace")
        return data 
    end
    
    -- Object counts (safe)
    local objectTypes = {
        "Generator", "Window", "Palletwrong", "PalletAlien", 
        "Hook", "Gate"
    }
    
    for _, objType in ipairs(objectTypes) do
        safePcall(function()
            local count = 0
            for _, obj in ipairs(map:GetDescendants()) do
                if obj.Name == objType then
                    count = count + 1
                end
            end
            if count > 0 then
                data.Objects[objType] = count
            end
        end)
    end
    
    -- Map structure (safe)
    safePcall(function()
        for _, child in ipairs(map:GetChildren()) do
            table.insert(data.Structure, child.Name .. " (" .. child.ClassName .. ")")
        end
    end)
    
    return data
end

local function ScanInputs()
    local data = {
        IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
        KeyboardEnabled = UserInputService.KeyboardEnabled,
        TouchEnabled = UserInputService.TouchEnabled,
        GamepadEnabled = UserInputService.GamepadEnabled
    }
    
    return data
end

-- Main Scan Function
function GameScanner:PerformScan()
    self.ScanData = {
        Timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        GameName = "Violence District",
        PlayerGUI = ScanPlayerGUI(),
        Character = ScanCharacter(),
        Remotes = ScanRemotes(),
        Map = ScanMap(),
        Input = ScanInputs()
    }
    
    return self.ScanData
end

-- Format scan data to readable string
function GameScanner:FormatData()
    local output = {}
    
    table.insert(output, "=".rep(60))
    table.insert(output, "VIOLENCE DISTRICT - GAME SCAN REPORT")
    table.insert(output, "Generated: " .. self.ScanData.Timestamp)
    table.insert(output, "=".rep(60))
    table.insert(output, "")
    
    -- Input System
    table.insert(output, "📱 INPUT SYSTEM:")
    table.insert(output, "  Platform: " .. (self.ScanData.Input.IsMobile and "Mobile" or "PC"))
    table.insert(output, "  Keyboard: " .. tostring(self.ScanData.Input.KeyboardEnabled))
    table.insert(output, "  Touch: " .. tostring(self.ScanData.Input.TouchEnabled))
    table.insert(output, "")
    
    -- Mobile Buttons
    if #self.ScanData.PlayerGUI.Mobile > 0 then
        table.insert(output, "🎮 MOBILE BUTTONS FOUND:")
        for i, btn in ipairs(self.ScanData.PlayerGUI.Mobile) do
            if i <= 20 then -- Limit to 20 buttons
                table.insert(output, string.format("  [%d] %s: '%s' (Parent: %s)", 
                    i, btn.Name, btn.Text, btn.Parent))
            end
        end
        if #self.ScanData.PlayerGUI.Mobile > 20 then
            table.insert(output, "  ... +" .. (#self.ScanData.PlayerGUI.Mobile - 20) .. " more buttons")
        end
        table.insert(output, "")
    end
    
    -- SkillCheck GUI
    if self.ScanData.PlayerGUI.Found.SkillCheckPromptGui then
        table.insert(output, "🎯 SKILLCHECK GUI:")
        table.insert(output, "  Path: " .. self.ScanData.PlayerGUI.Found.SkillCheckPromptGui.Path)
        table.insert(output, "  Elements: " .. table.concat(self.ScanData.PlayerGUI.Found.SkillCheckPromptGui.Children, ", "))
        table.insert(output, "")
    end
    
    -- Character
    if self.ScanData.Character.Humanoid then
        table.insert(output, "🧍 CHARACTER INFO:")
        table.insert(output, "  WalkSpeed: " .. self.ScanData.Character.Humanoid.WalkSpeed)
        table.insert(output, "  Health: " .. self.ScanData.Character.Humanoid.Health .. "/" .. self.ScanData.Character.Humanoid.MaxHealth)
        if next(self.ScanData.Character.Humanoid.Attributes) then
            table.insert(output, "  Attributes: " .. table.concat(self.ScanData.Character.Humanoid.Attributes, ", "))
        end
        table.insert(output, "")
    end
    
    -- Map Objects
    if next(self.ScanData.Map.Objects) then
        table.insert(output, "🗺️ MAP OBJECTS:")
        for objType, count in pairs(self.ScanData.Map.Objects) do
            table.insert(output, "  " .. objType .. ": " .. count)
        end
        table.insert(output, "")
    end
    
    -- Remotes
    if #self.ScanData.Remotes.ReplicatedStorage > 0 then
        table.insert(output, "📡 REMOTES FOUND:")
        for i, remote in ipairs(self.ScanData.Remotes.ReplicatedStorage) do
            if i <= 10 then
                table.insert(output, "  " .. remote.Name .. " (" .. remote.Type .. ")")
            end
        end
        if #self.ScanData.Remotes.ReplicatedStorage > 10 then
            table.insert(output, "  ... +" .. (#self.ScanData.Remotes.ReplicatedStorage - 10) .. " more")
        end
        table.insert(output, "")
    end
    
    table.insert(output, "=".rep(60))
    
    return table.concat(output, "\n")
end

-- ============================================
-- Initialize
-- ============================================

local UI = CreateUI()

-- ════════════════════════════════════════
-- BUTTON HANDLERS
-- ════════════════════════════════════════

local function InitializeUI()
    local UI = CreateUI()
    
    if not UI then
        warn("[GameScanner] Failed to create UI")
        return
    end
    
    GameScanner.UI = UI
    
    -- Scan Button Handler
    UI.ScanButton.MouseButton1Click:Connect(function()
        UI.StatusLabel.Text = "Scanning..."
        UI.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        -- Clear previous results
        for _, child in ipairs(UI.ContentFrame:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        task.wait(0.3)
        
        -- Perform scan
        local scanData = GameScanner:PerformScan()
        
        -- Display results
        AddResultText(UI.ContentFrame, "=".rep(40), Color3.fromRGB(100, 150, 255))
        AddResultText(UI.ContentFrame, "VIOLENCE DISTRICT - SCAN RESULTS", Color3.fromRGB(100, 200, 255))
        AddResultText(UI.ContentFrame, "Generated: " .. os.date("%H:%M:%S"), Color3.fromRGB(150, 150, 150))
        AddResultText(UI.ContentFrame, "=".rep(40), Color3.fromRGB(100, 150, 255))
        AddResultText(UI.ContentFrame, "", Color3.fromRGB(255, 255, 255))
        
        -- Input System
        AddResultText(UI.ContentFrame, "INPUT SYSTEM:", Color3.fromRGB(255, 200, 100))
        AddResultText(UI.ContentFrame, "  Platform: " .. (scanData.Input.IsMobile and "MOBILE" or "PC"))
        AddResultText(UI.ContentFrame, "  Touch: " .. tostring(scanData.Input.TouchEnabled))
        AddResultText(UI.ContentFrame, "", Color3.fromRGB(255, 255, 255))
        
        -- Mobile Buttons
        if #scanData.PlayerGUI.Mobile > 0 then
            AddResultText(UI.ContentFrame, "MOBILE BUTTONS (" .. #scanData.PlayerGUI.Mobile .. " found):", Color3.fromRGB(100, 255, 150))
            local shown = 0
            for i, btn in ipairs(scanData.PlayerGUI.Mobile) do
                if shown < 15 then
                    AddResultText(UI.ContentFrame, string.format("  [%d] %s: '%s'", i, btn.Name, btn.Text))
                    shown = shown + 1
                end
            end
            if #scanData.PlayerGUI.Mobile > 15 then
                AddResultText(UI.ContentFrame, "  ... +" .. (#scanData.PlayerGUI.Mobile - 15) .. " more")
            end
            AddResultText(UI.ContentFrame, "", Color3.fromRGB(255, 255, 255))
        end
        
        -- Character Info
        if scanData.Character.Humanoid then
            AddResultText(UI.ContentFrame, "CHARACTER:", Color3.fromRGB(255, 150, 100))
            AddResultText(UI.ContentFrame, "  WalkSpeed: " .. scanData.Character.Humanoid.WalkSpeed)
            AddResultText(UI.ContentFrame, "  Health: " .. scanData.Character.Humanoid.Health .. "/" .. scanData.Character.Humanoid.MaxHealth)
            AddResultText(UI.ContentFrame, "", Color3.fromRGB(255, 255, 255))
        end
        
        -- Map Objects
        if next(scanData.Map.Objects) then
            AddResultText(UI.ContentFrame, "MAP OBJECTS:", Color3.fromRGB(150, 255, 150))
            for objType, count in pairs(scanData.Map.Objects) do
                AddResultText(UI.ContentFrame, "  " .. objType .. ": " .. count)
            end
            AddResultText(UI.ContentFrame, "", Color3.fromRGB(255, 255, 255))
        end
        
        -- Remotes
        if #scanData.Remotes.ReplicatedStorage > 0 then
            AddResultText(UI.ContentFrame, "REMOTES (" .. #scanData.Remotes.ReplicatedStorage .. " found):", Color3.fromRGB(255, 200, 150))
            for i = 1, math.min(10, #scanData.Remotes.ReplicatedStorage) do
                local remote = scanData.Remotes.ReplicatedStorage[i]
                AddResultText(UI.ContentFrame, "  " .. remote.Name .. " (" .. remote.Type .. ")")
            end
            if #scanData.Remotes.ReplicatedStorage > 10 then
                AddResultText(UI.ContentFrame, "  ... +" .. (#scanData.Remotes.ReplicatedStorage - 10) .. " more")
            end
        end
        
        AddResultText(UI.ContentFrame, "", Color3.fromRGB(255, 255, 255))
        AddResultText(UI.ContentFrame, "=".rep(40), Color3.fromRGB(100, 150, 255))
        
        UI.StatusLabel.Text = "Scan complete!"
        UI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)
    
    -- Copy Button Handler
    UI.CopyButton.MouseButton1Click:Connect(function()
        if not GameScanner.ScanData.Timestamp then
            UI.StatusLabel.Text = "Please scan first!"
            UI.StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        
        local formatted = GameScanner:FormatData()
        
        -- Try to copy
        local success = pcall(function()
            setclipboard(formatted)
        end)
        
        if success then
            UI.StatusLabel.Text = "Copied to clipboard!"
            UI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            UI.StatusLabel.Text = "Clipboard not supported (check console)"
            UI.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            print("\n" .. formatted .. "\n")
        end
    end)
    
    print("[GameScanner] UI initialized successfully")
end

-- ════════════════════════════════════════
-- INITIALIZE
-- ════════════════════════════════════════

print("[GameScanner] Initializing UI...")
InitializeUI()
print("[GameScanner] Ready! Open the GUI and click 'Scan Game'")

return GameScanner
