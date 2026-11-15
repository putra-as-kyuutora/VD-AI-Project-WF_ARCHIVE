-- ============================================
-- Violence District Game Scanner
-- Scans game structure and saves configuration for AI
-- ============================================

local GameScanner = {
    Version = "1.0.0",
    ScanData = {}
}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Safe pcall wrapper
local function safePcall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[GameScanner Error] " .. tostring(result))
        return nil
    end
    return result
end

-- ============================================
-- UI Creation
-- ============================================

local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GameScannerUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Parent to PlayerGui (safer for mobile)
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.Parent = playerGui
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 600)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Add corner radius
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "🔍 Violence District - Game Scanner"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 16
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    CloseButton.Text = "✕"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 16
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.BorderSizePixel = 0
    CloseButton.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Scroll Frame for Content
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Name = "ScrollFrame"
    ScrollFrame.Size = UDim2.new(1, -20, 1, -130)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 50)
    ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollFrame.Parent = MainFrame
    
    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 6)
    ScrollCorner.Parent = ScrollFrame
    
    -- List Layout for content
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 8)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ScrollFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.PaddingRight = UDim.new(0, 10)
    Padding.PaddingTop = UDim.new(0, 10)
    Padding.PaddingBottom = UDim.new(0, 10)
    Padding.Parent = ScrollFrame
    
    -- Output Text Label
    local OutputLabel = Instance.new("TextLabel")
    OutputLabel.Name = "OutputLabel"
    OutputLabel.Size = UDim2.new(1, -20, 0, 30)
    OutputLabel.Position = UDim2.new(0, 10, 1, -75)
    OutputLabel.BackgroundTransparency = 1
    OutputLabel.Text = "Status: Ready to scan"
    OutputLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
    OutputLabel.TextSize = 12
    OutputLabel.Font = Enum.Font.GothamMedium
    OutputLabel.TextXAlignment = Enum.TextXAlignment.Left
    OutputLabel.Parent = MainFrame
    
    -- Button Container
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Name = "ButtonFrame"
    ButtonFrame.Size = UDim2.new(1, -20, 0, 35)
    ButtonFrame.Position = UDim2.new(0, 10, 1, -40)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.Parent = MainFrame
    
    -- Scan Button
    local ScanButton = Instance.new("TextButton")
    ScanButton.Name = "ScanButton"
    ScanButton.Size = UDim2.new(0.48, 0, 1, 0)
    ScanButton.Position = UDim2.new(0, 0, 0, 0)
    ScanButton.BackgroundColor3 = Color3.fromRGB(60, 150, 255)
    ScanButton.Text = "🔍 Scan Game"
    ScanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ScanButton.TextSize = 14
    ScanButton.Font = Enum.Font.GothamBold
    ScanButton.BorderSizePixel = 0
    ScanButton.Parent = ButtonFrame
    
    local ScanCorner = Instance.new("UICorner")
    ScanCorner.CornerRadius = UDim.new(0, 6)
    ScanCorner.Parent = ScanButton
    
    -- Save Button
    local SaveButton = Instance.new("TextButton")
    SaveButton.Name = "SaveButton"
    SaveButton.Size = UDim2.new(0.48, 0, 1, 0)
    SaveButton.Position = UDim2.new(0.52, 0, 0, 0)
    SaveButton.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
    SaveButton.Text = "💾 Copy to Clipboard"
    SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveButton.TextSize = 14
    SaveButton.Font = Enum.Font.GothamBold
    SaveButton.BorderSizePixel = 0
    SaveButton.Parent = ButtonFrame
    
    local SaveCorner = Instance.new("UICorner")
    SaveCorner.CornerRadius = UDim.new(0, 6)
    SaveCorner.Parent = SaveButton
    
    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        ScrollFrame = ScrollFrame,
        OutputLabel = OutputLabel,
        ScanButton = ScanButton,
        SaveButton = SaveButton
    }
end

-- ============================================
-- Scan Functions
-- ============================================

local function AddSectionToUI(scrollFrame, title, content, color)
    local Section = Instance.new("Frame")
    Section.Name = title
    Section.Size = UDim2.new(1, 0, 0, 0)
    Section.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Section.BorderSizePixel = 0
    Section.AutomaticSize = Enum.AutomaticSize.Y
    Section.Parent = scrollFrame
    
    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 6)
    SectionCorner.Parent = Section
    
    local SectionLayout = Instance.new("UIListLayout")
    SectionLayout.Padding = UDim.new(0, 5)
    SectionLayout.Parent = Section
    
    local SectionPadding = Instance.new("UIPadding")
    SectionPadding.PaddingLeft = UDim.new(0, 10)
    SectionPadding.PaddingRight = UDim.new(0, 10)
    SectionPadding.PaddingTop = UDim.new(0, 8)
    SectionPadding.PaddingBottom = UDim.new(0, 8)
    SectionPadding.Parent = Section
    
    -- Title
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 20)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "📋 " .. title
    TitleLabel.TextColor3 = color or Color3.fromRGB(100, 180, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Section
    
    -- Content
    local ContentLabel = Instance.new("TextLabel")
    ContentLabel.Size = UDim2.new(1, 0, 0, 0)
    ContentLabel.BackgroundTransparency = 1
    ContentLabel.Text = content
    ContentLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    ContentLabel.TextSize = 11
    ContentLabel.Font = Enum.Font.Code
    ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    ContentLabel.TextYAlignment = Enum.TextYAlignment.Top
    ContentLabel.TextWrapped = true
    ContentLabel.AutomaticSize = Enum.AutomaticSize.Y
    ContentLabel.Parent = Section
end

local function ScanPlayerGUI()
    local data = {
        Found = {},
        Mobile = {}
    }
    
    local success, playerGui = pcall(function()
        return LocalPlayer:FindFirstChild("PlayerGui")
    end)
    
    if not success or not playerGui then 
        warn("[GameScanner] PlayerGui not found")
        return data 
    end
    
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
    
    -- Scan for Mobile Buttons (safe iteration)
    for _, gui in ipairs(playerGui:GetChildren()) do
        safePcall(function()
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
        end)
    end
    
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

-- Scan Button Handler
UI.ScanButton.MouseButton1Click:Connect(function()
    UI.OutputLabel.Text = "Status: Scanning..."
    UI.OutputLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    -- Clear previous results
    for _, child in ipairs(UI.ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    task.wait(0.5)
    
    -- Perform scan
    local scanData = GameScanner:PerformScan()
    
    -- Display results
    local formatted = GameScanner:FormatData()
    
    AddSectionToUI(UI.ScrollFrame, "Scan Results", formatted, Color3.fromRGB(100, 200, 255))
    
    UI.OutputLabel.Text = "Status: Scan complete! ✅"
    UI.OutputLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
end)

-- Save Button Handler
UI.SaveButton.MouseButton1Click:Connect(function()
    if not GameScanner.ScanData.Timestamp then
        UI.OutputLabel.Text = "Status: Please scan first!"
        UI.OutputLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    local formatted = GameScanner:FormatData()
    
    -- Copy to clipboard (if supported)
    local success = pcall(function()
        setclipboard(formatted)
    end)
    
    if success then
        UI.OutputLabel.Text = "Status: Copied to clipboard! 📋"
        UI.OutputLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        UI.OutputLabel.Text = "Status: Clipboard not supported. Check console for output."
        UI.OutputLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        print("\n" .. formatted .. "\n")
    end
end)

print("🔍 Game Scanner loaded! UI should be visible.")
print("📱 Use the UI to scan Violence District game structure.")

return GameScanner
