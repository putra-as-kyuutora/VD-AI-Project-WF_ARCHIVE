-- WolfFamilyHub V0.1.0-Fix-28_RELEASE
-- Built: June 27, 2026
-- THEME: Official WolfFamily Branding (Dark Surface + Wolf Red)
-- FEATURES: SixSense + General Tab + Camera Unlock + Invisible Attack + Emote Player

print("[WolfHub] Starting Fix-28 Early...")

-- Anti-cheat bypass
local cloneref = cloneref or function(instance) return instance end

local Services = {
    Players = cloneref(game:GetService("Players")),
    RunService = cloneref(game:GetService("RunService")),
    UserInputService = cloneref(game:GetService("UserInputService")),
    ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage")),
    Workspace = cloneref(game:GetService("Workspace")),
    VirtualInputManager = cloneref(game:GetService("VirtualInputManager")),
    GuiService = cloneref(game:GetService("GuiService")),
    Lighting = cloneref(game:GetService("Lighting"))
}

local LocalPlayer = Services.Players.LocalPlayer

-- ========================================
-- GLOBAL TEAM HELPER FUNCTIONS
-- ========================================
_G.IsKiller = function()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
end

_G.IsSurvivor = function()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Survivor"
end

_G.IsSpectator = function()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Spectator"
end

_G.GetPlayerTeam = function()
    return LocalPlayer.Team and LocalPlayer.Team.Name or "NO TEAM"
end

_G.GetTeamColor = function()
    return LocalPlayer.Team and LocalPlayer.Team.TeamColor or nil
end

print("[Team Helper] Global team functions loaded")

-- ========================================
-- GETGAMEVALUE HELPER FUNCTION
-- ========================================
function GetGameValue(obj, name)
    if not obj then return nil end
    
    -- Try attribute first (most common)
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    
    -- Try ValueBase child (StringValue, IntValue, etc.)
    local child = obj:FindFirstChild(name)
    if child then
        local success, val = pcall(function() return child.Value end)
        if success then return val end
    end
    
    return nil
end

print("[GetGameValue] Helper function loaded")

-- ========================================
-- DEV CONSOLE SYSTEM
-- ========================================
_G.DevConsole = _G.DevConsole or {
    Logs = {},
    MaxLogs = 100,
    Enabled = false
}

local function DevLog(message, type)
    type = type or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logEntry = string.format("[%s] [%s] %s", timestamp, type, tostring(message))
    
    table.insert(_G.DevConsole.Logs, logEntry)
    
    -- Keep only last MaxLogs entries
    if #_G.DevConsole.Logs > _G.DevConsole.MaxLogs then
        table.remove(_G.DevConsole.Logs, 1)
    end
    
    -- Also print to regular console
    if _G.DevConsole.Enabled then
        print(logEntry)
    end
end

local function GetConsoleLogs()
    return table.concat(_G.DevConsole.Logs, "\n")
end

local function ClearConsoleLogs()
    _G.DevConsole.Logs = {}
    DevLog("Console cleared", "SYSTEM")
end

DevLog("WolfHub initializing...", "SYSTEM")

print("[WolfHub] Loading Obsidian UI...")

-- Load Obsidian Library
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- NO THEME CUSTOMIZATION - Use default Obsidian theme
-- To apply WolfFamily theme, use Settings > Configuration > Load Config
-- Import: WolfFamily_Theme.json

-- Create Window (Fixed size, no DPI scale)
local Window = Library:CreateWindow({
    Title = "WolfFamily",
    Footer = "V0.1.0-Fix-28 RELEASE | Invisible Attack + Emote Player",
    NotifySide = "Right",
    ShowCustomCursor = true,
    Center = true,
    AutoShow = true,
    Resizable = true,
    MobileButtonsSide = "Right",
    Size = UDim2.new(0, 650, 0, 450)  -- Fixed size for all devices
})

print("[WolfHub] Window created!")

-- ========================================
-- WOLFFAMILY LOGO & CUSTOM CURSOR (GitHub Asset)
-- ========================================

pcall(function()
    local ImageManager = Library.ImageManager
    
    -- Add WolfFamily logo from GitHub
    -- URL: https://github.com/WolfFamily-KyS/Wolf-Family-Hub/blob/main/Wolf_family.png
    -- Raw URL for direct download
    ImageManager.AddAsset(
        "wolffamily_logo",
        0,  -- No Roblox Asset ID (GitHub only)
        "https://raw.githubusercontent.com/WolfFamily-KyS/Wolf-Family-Hub/main/Wolf_family.png"
    )
    
    print("[WolfHub] Logo loaded from GitHub")
    
    -- Use logo as custom cursor
    task.wait(0.5)  -- Wait for logo to download
    local logoAsset = ImageManager.GetAsset("wolffamily_logo")
    
    if logoAsset and logoAsset ~= "" then
        Library:ChangeCursorIcon(logoAsset)
        Library:ChangeCursorIconSize(UDim2.new(0, 32, 0, 32))  -- 32x32 size
        print("[WolfHub] Custom cursor applied (WolfFamily logo)")
    else
        print("[WolfHub] Logo not available, using default cursor")
    end
end)

-- ========================================
-- DRAGGABLE STATUS LABEL (Obsidian API - Simple)
-- ========================================

local DraggableLabel = Library:AddDraggableLabel("WolfFamily | 60 fps | 0 ms")
DraggableLabel:SetVisible(true)

-- FPS & Ping tracking
local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

Services.RunService.RenderStepped:Connect(function()
    FrameCounter = FrameCounter + 1
    
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    
    local ping = math.floor(Services.Players.LocalPlayer:GetNetworkPing() * 1000)
    DraggableLabel:SetText(string.format('WolfFamily | %s fps | %s ms', math.floor(FPS), ping))
end)

DevLog("Draggable label created (simple)", "SYSTEM")

-- ========================================
-- MOBILE SHORTCUTS SYSTEM (Fix-27) - NO GETGENV
-- ========================================

_G.MobileShortcuts = {
    Enabled = true,
    AutoParry = false,
    FakeAttack = false,
    AttackAnim = false,
    SpeedBoost = false,
    CameraUnlock = false,
    SilentAim = false,
    AutoTeleport = false
}

_G.ShortcutsLocked = false
local ShortcutButtons = {
    AutoParry = nil,
    FakeAttack = nil,
    AttackAnim = nil,
    SpeedBoost = nil,
    CameraUnlock = nil,
    SilentAim = nil,
    AutoTeleport = nil
}
local isInitializing = false

-- Helper functions to enable/disable dragging per button
local function DisableButtonDrag(button)
    if not button or not button.Button then return end
    
    -- Capture CURRENT position when locking (not default position)
    button._OriginalPosition = button.Button.Position
    button._DragDisabled = true
    
    -- Monitor position changes and force reset
    if not button._PositionConnection then
        button._PositionConnection = button.Button:GetPropertyChangedSignal("Position"):Connect(function()
            if button._DragDisabled and button._OriginalPosition then
                -- Immediately reset to locked position (no task.wait)
                if button.Button.Position ~= button._OriginalPosition then
                    button.Button.Position = button._OriginalPosition
                end
            end
        end)
    end
    
    print(string.format("[Lock] Button locked at position: %s", tostring(button._OriginalPosition)))
end

local function EnableButtonDrag(button)
    if not button or not button.Button then return end
    
    button._DragDisabled = false
    
    print("[Unlock] Button unlocked, can be dragged")
end

local function SetButtonsDraggable(enabled)
    for key, btn in pairs(ShortcutButtons) do
        if btn and btn.Button and btn.Button.Parent and btn.Button.Visible then
            if enabled then
                EnableButtonDrag(btn)
            else
                DisableButtonDrag(btn)
            end
        end
    end
end

local function CreateToggleShortcut(name, globalVar, defaultPos, toggleKey)
    local button = Library:AddDraggableButton(name, function(self)
        if not self or not self.Button then return end
        pcall(function()
            _G[globalVar] = not _G[globalVar]
            local isOn = _G[globalVar]
            
            -- Sync with UI toggle if exists
            if toggleKey and Toggles[toggleKey] then
                Toggles[toggleKey]:SetValue(isOn)
            end
            
            Library:Notify(string.format("%s: %s", name, isOn and "ON" or "OFF"), 1)
        end)
    end, false, false)
    
    if button and button.Button then
        button.Button.Position = defaultPos
        button.Button.AnchorPoint = Vector2.new(1, 0)
        button.Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        
        -- Initialize drag state (don't set _OriginalPosition yet)
        button._DragDisabled = false
        
        -- Apply lock state if already locked
        if _G.ShortcutsLocked then
            DisableButtonDrag(button)
        end
    end
    return button
end

local function CreateActionShortcut(name, callback, defaultPos, buttonColor)
    local button = Library:AddDraggableButton(name, function(self)
        if not self or not self.Button or not self.Button.Parent then return end
        
        task.spawn(function()
            pcall(function()
                callback()
            end)
        end)
    end, false, false)
    
    if button and button.Button then
        button.Button.Position = defaultPos
        button.Button.AnchorPoint = Vector2.new(1, 0)
        button.Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        
        -- Initialize drag state (don't set _OriginalPosition yet)
        button._DragDisabled = false
        
        -- Apply lock state if already locked
        if _G.ShortcutsLocked then
            DisableButtonDrag(button)
        end
    end
    return button
end

local function InitializeShortcuts()
    if isInitializing then 
        print("[Mobile Shortcuts] Already initializing, skipping...")
        return 
    end
    
    isInitializing = true
    
    -- Hide all buttons first
    for key, btn in pairs(ShortcutButtons) do
        if btn and btn.Button and btn.Button.Parent then
            btn.Button.Visible = false
        end
    end
    
    if not _G.MobileShortcuts.Enabled then 
        isInitializing = false
        return 
    end
    
    -- Dynamic positioning logic
    local currentY = 86
    local currentXOffset = -6
    local function GetNextPosition()
        local pos = UDim2.new(1, currentXOffset, 0, currentY)
        currentY = currentY + 40
        if currentY > 280 then -- wrap to left for smaller screens
            currentY = 86
            currentXOffset = currentXOffset - 60 -- Shift left for next column
        end
        return pos
    end
    
    -- Show/create Auto Parry button
    if _G.MobileShortcuts.AutoParry then
        local pos = GetNextPosition()
        if not ShortcutButtons.AutoParry or not ShortcutButtons.AutoParry.Button or not ShortcutButtons.AutoParry.Button.Parent then
            ShortcutButtons.AutoParry = CreateToggleShortcut("Parry", "AutoParryEnabled", pos, "AutoParry")
        else
            ShortcutButtons.AutoParry.Button.Position = pos
            ShortcutButtons.AutoParry.Button.Visible = true
        end
    end
    
    -- Show/create Fake Attack button (NOW INVISIBLE ATTACK)
    if _G.MobileShortcuts.FakeAttack then
        local pos = GetNextPosition()
        if not ShortcutButtons.FakeAttack or not ShortcutButtons.FakeAttack.Button or not ShortcutButtons.FakeAttack.Button.Parent then
            ShortcutButtons.FakeAttack = CreateActionShortcut("Attack", function()
                if type(_G.ExecuteInvisibleAttack) == "function" then
                    _G.ExecuteInvisibleAttack()
                else
                    Library:Notify("Invisible Attack not available", 2)
                end
            end, pos, Color3.fromRGB(0, 0, 0))
        else
            ShortcutButtons.FakeAttack.Button.Position = pos
            ShortcutButtons.FakeAttack.Button.Visible = true
        end
    end
    
    -- Show/create Attack Anim button
    if _G.MobileShortcuts.AttackAnim then
        local pos = GetNextPosition()
        if not ShortcutButtons.AttackAnim or not ShortcutButtons.AttackAnim.Button or not ShortcutButtons.AttackAnim.Button.Parent then
            ShortcutButtons.AttackAnim = CreateActionShortcut("Anim", function()
                if type(_G.ExecuteAttackAnimation) == "function" then
                    _G.ExecuteAttackAnimation()
                else
                    Library:Notify("Attack Anim not available", 2)
                end
            end, pos, Color3.fromRGB(0, 0, 0))
        else
            ShortcutButtons.AttackAnim.Button.Position = pos
            ShortcutButtons.AttackAnim.Button.Visible = true
        end
    end
    
    -- Show/create Speed Boost button
    if _G.MobileShortcuts.SpeedBoost then
        local pos = GetNextPosition()
        if not ShortcutButtons.SpeedBoost or not ShortcutButtons.SpeedBoost.Button or not ShortcutButtons.SpeedBoost.Button.Parent then
            ShortcutButtons.SpeedBoost = CreateToggleShortcut("Speed", "SpeedBoostEnabled", pos, "SpeedBoostToggle")
        else
            ShortcutButtons.SpeedBoost.Button.Position = pos
            ShortcutButtons.SpeedBoost.Button.Visible = true
        end
    end
    
    -- Show/create Camera Unlock button
    if _G.MobileShortcuts.CameraUnlock then
        local pos = GetNextPosition()
        if not ShortcutButtons.CameraUnlock or not ShortcutButtons.CameraUnlock.Button or not ShortcutButtons.CameraUnlock.Button.Parent then
            ShortcutButtons.CameraUnlock = CreateToggleShortcut("Camera", "CameraUnlocked", pos, nil)
        else
            ShortcutButtons.CameraUnlock.Button.Position = pos
            ShortcutButtons.CameraUnlock.Button.Visible = true
        end
    end
    
    -- Show/create Auto Teleport button
    if _G.MobileShortcuts.AutoTeleport then
        local pos = GetNextPosition()
        if not ShortcutButtons.AutoTeleport or not ShortcutButtons.AutoTeleport.Button or not ShortcutButtons.AutoTeleport.Button.Parent then
            ShortcutButtons.AutoTeleport = CreateActionShortcut("Teleport", function()
                -- Manual trigger for Auto Teleport
                local char = LocalPlayer.Character
                if not char then
                    Library:Notify("Character not found", 2)
                    return
                end
                
                local myRoot = char:FindFirstChild("HumanoidRootPart")
                if not myRoot then
                    Library:Notify("HumanoidRootPart not found", 2)
                    return
                end
                
                -- Check if in valid state
                local isValid, reason = IsSurvivorInValidState()
                if not isValid then
                    Library:Notify("Cannot teleport: " .. reason, 2)
                    return
                end
                
                -- Find nearest killer
                local nearestKiller = nil
                local nearestDistance = math.huge
                
                for _, player in pairs(Services.Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Team and player.Team.Name == "Killer" then
                        local killerChar = player.Character
                        if killerChar then
                            local killerRoot = killerChar:FindFirstChild("HumanoidRootPart")
                            if killerRoot then
                                local distance = (killerRoot.Position - myRoot.Position).Magnitude
                                if distance < nearestDistance and distance <= _G.ParryRange then
                                    nearestDistance = distance
                                    nearestKiller = killerRoot
                                end
                            end
                        end
                    end
                end
                
                if not nearestKiller then
                    Library:Notify("No killer in range", 2)
                    return
                end
                
                -- Execute teleport
                local success = AutoTeleportAway(nearestKiller, myRoot)
                if success then
                    Library:Notify("Teleported!", 1)
                else
                    Library:Notify("Teleport on cooldown", 2)
                end
            end, pos, Color3.fromRGB(0, 0, 0))
        else
            ShortcutButtons.AutoTeleport.Button.Position = pos
            ShortcutButtons.AutoTeleport.Button.Visible = true
        end
    end
    
    -- Show/create Silent Aim button
    if _G.MobileShortcuts.SilentAim then
        local pos = GetNextPosition()
        if not ShortcutButtons.SilentAim or not ShortcutButtons.SilentAim.Button or not ShortcutButtons.SilentAim.Button.Parent then
            ShortcutButtons.SilentAim = CreateActionShortcut("🎯 Aim", function()
                if type(_G.ExecuteSilentAim) == "function" then
                    _G.ExecuteSilentAim()
                else
                    Library:Notify("Silent Aim not available", 2)
                end
            end, pos, Color3.fromRGB(0, 0, 0))
        else
            ShortcutButtons.SilentAim.Button.Position = pos
            ShortcutButtons.SilentAim.Button.Visible = true
        end
    end
    
    isInitializing = false
    
    local visibleCount = 0
    for key, btn in pairs(ShortcutButtons) do
        if btn and btn.Button and btn.Button.Visible then
            visibleCount = visibleCount + 1
        end
    end
    print(string.format("[Mobile Shortcuts] Initialized: %d visible buttons", visibleCount))
end

print("[Mobile Shortcuts] System loaded")

-- ========================================
-- CREATE TABS
-- ========================================

local Tabs = {
    General = Window:AddTab("General", "home"),
    Survivor = Window:AddTab("Survivor", "play"),
    Aim = Window:AddTab("Aim", "crosshair"),
    Killer = Window:AddTab("Killer", "skull"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Settings = Window:AddTab("Settings", "settings")
}

-- ========================================
-- GENERAL TAB (Camera & FOV)
-- ========================================

local CameraGroupBox = Tabs.General:AddLeftGroupbox("Camera", "camera")

-- Unlock Camera (Infinite Zoom Out)
_G.CameraUnlocked = false
local CameraConnection = nil
local OriginalMaxZoomDistance = nil

CameraGroupBox:AddToggle("UnlockCamera", {
    Text = "Unlock Camera",
    Default = false,
    Tooltip = "Infinite zoom out (no distance limit)",
    Callback = function(Value)
        _G.CameraUnlocked = Value
        
        if Value then
            -- Save original max zoom distance
            if LocalPlayer.CameraMaxZoomDistance then
                OriginalMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance
            end
            
            -- Set to infinite
            LocalPlayer.CameraMaxZoomDistance = math.huge
            
            -- Keep it enforced
            if not CameraConnection then
                CameraConnection = Services.RunService.Heartbeat:Connect(function()
                    if _G.CameraUnlocked then
                        LocalPlayer.CameraMaxZoomDistance = math.huge
                    end
                end)
            end
            
            print("[Camera] Unlocked - Infinite zoom out")
        else
            -- Restore original
            if OriginalMaxZoomDistance then
                LocalPlayer.CameraMaxZoomDistance = OriginalMaxZoomDistance
            else
                LocalPlayer.CameraMaxZoomDistance = 400  -- Default Roblox value
            end
            
            -- Disconnect loop
            if CameraConnection then
                CameraConnection:Disconnect()
                CameraConnection = nil
            end
            
            print("[Camera] Locked - Restored to:", LocalPlayer.CameraMaxZoomDistance)
        end
    end
})

CameraGroupBox:AddDivider()

-- FOV Changer (MOVED FROM VISUALS TAB)
_G.FOVEnabled = false
_G.CustomFOV = 70
local OriginalFOV = 70

CameraGroupBox:AddToggle("FOVChanger", {
    Text = "FOV Changer",
    Default = false,
    Tooltip = "Change field of view",
    Callback = function(Value)
        _G.FOVEnabled = Value
        
        local camera = Services.Workspace.CurrentCamera
        if camera then
            if Value then
                OriginalFOV = camera.FieldOfView
                camera.FieldOfView = _G.CustomFOV
                print("[FOV] Enabled:", _G.CustomFOV)
            else
                camera.FieldOfView = OriginalFOV
                print("[FOV] Disabled, restored to:", OriginalFOV)
            end
        end
    end
})

CameraGroupBox:AddSlider("FOVValue", {
    Text = "FOV Value",
    Default = 70,
    Min = 60,
    Max = 120,
    Rounding = 0,
    Compact = false,
    Tooltip = "Adjust field of view (60-120)",
    Callback = function(Value)
        _G.CustomFOV = Value
        
        if _G.FOVEnabled then
            local camera = Services.Workspace.CurrentCamera
            if camera then
                camera.FieldOfView = Value
                print("[FOV] Changed to:", Value)
            end
        end
    end
})

-- ========================================
-- SPEED BOOST SYSTEM (General Tab - RIGHT SIDE)
-- ========================================

local SpeedBoostGroupBox = Tabs.General:AddRightGroupbox("Speed Boost", "zap")

_G.SpeedBoostPercent = 0
_G.SpeedBoostEnabled = false
local SpeedConnection = nil

SpeedBoostGroupBox:AddToggle("SpeedBoostToggle", {
    Text = "Enable Speed Boost",
    Default = false,
    Callback = function(Value)
        _G.SpeedBoostEnabled = Value
        print("[Speed Boost] " .. (Value and "ENABLED" or "DISABLED"))
        
        -- Reset speed when disabled
        if not Value then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.WalkSpeed = 16
                    end
                end
            end)
        end
    end
})

SpeedBoostGroupBox:AddLabel("Boost Speed (0-100% extra)")
SpeedBoostGroupBox:AddSlider("SpeedBoostSlider", {
    Text = "Speed Boost",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Compact = false,
    Suffix = "%",
    Callback = function(Value)
        _G.SpeedBoostPercent = Value
        print("[Speed Boost] Set to:", Value .. "%")
    end
})

SpeedBoostGroupBox:AddDivider()
SpeedBoostGroupBox:AddLabel("Animation stays normal")
SpeedBoostGroupBox:AddLabel("Works for Killer & Survivor")

-- Speed Boost Logic with Animation Lock (always on)
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    -- Only apply speed boost if enabled
                    if _G.SpeedBoostEnabled and _G.SpeedBoostPercent > 0 then
                        local baseSpeed = 16
                        local multiplier = 1 + (_G.SpeedBoostPercent / 100)
                        humanoid.WalkSpeed = baseSpeed * multiplier
                    elseif not _G.SpeedBoostEnabled then
                        humanoid.WalkSpeed = 16
                    end
                    
                    -- ALWAYS lock animation speed to normal
                    local animator = humanoid:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                            if track.Speed ~= 1.0 then
                                track:AdjustSpeed(1.0)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

print("[Speed Boost] System loaded")

-- ========================================
-- MOBILE SHORTCUTS SETTINGS (General Tab - RIGHT SIDE)
-- ========================================

local MobileShortcutsGroupBox = Tabs.General:AddRightGroupbox("Mobile Shortcuts", "smartphone")

MobileShortcutsGroupBox:AddLabel("Floating Quick Access Buttons")
MobileShortcutsGroupBox:AddDivider()

MobileShortcutsGroupBox:AddToggle("EnableShortcuts", {
    Text = "Mobile Shortcuts",
    Default = true,
    Tooltip = "Show/hide floating buttons",
    Callback = function(Value)
        _G.MobileShortcuts.Enabled = Value
        InitializeShortcuts()
        Library:Notify("Mobile Shortcuts: " .. (Value and "ON" or "OFF"), 1)
    end
})

MobileShortcutsGroupBox:AddToggle("LockShortcuts", {
    Text = "Lock Shortcuts",
    Default = false,
    Tooltip = "Prevent shortcuts from being dragged",
    Callback = function(Value)
        _G.ShortcutsLocked = Value
        
        -- Enable/disable dragging for all shortcut buttons
        SetButtonsDraggable(not Value)
        
        Library:Notify("Shortcuts: " .. (Value and "LOCKED" or "UNLOCKED"), 1)
        print("[Mobile Shortcuts] Lock status:", Value and "LOCKED" or "UNLOCKED")
    end
})

MobileShortcutsGroupBox:AddDivider()
MobileShortcutsGroupBox:AddLabel("Select Buttons:")

MobileShortcutsGroupBox:AddToggle("ShortcutAutoParry", {
    Text = "Auto Parry Button",
    Default = false,
    Callback = function(Value)
        _G.MobileShortcuts.AutoParry = Value
        InitializeShortcuts()
    end
})

MobileShortcutsGroupBox:AddToggle("ShortcutFakeAttack", {
    Text = "Invisible Attack Button",
    Default = false,
    Callback = function(Value)
        _G.MobileShortcuts.FakeAttack = Value
        InitializeShortcuts()
    end
})

MobileShortcutsGroupBox:AddToggle("ShortcutAttackAnim", {
    Text = "Attack Anim Button",
    Default = false,
    Callback = function(Value)
        _G.MobileShortcuts.AttackAnim = Value
        InitializeShortcuts()
    end
})

MobileShortcutsGroupBox:AddToggle("ShortcutSpeedBoost", {
    Text = "Speed Boost Button",
    Default = false,
    Callback = function(Value)
        _G.MobileShortcuts.SpeedBoost = Value
        InitializeShortcuts()
    end
})

MobileShortcutsGroupBox:AddToggle("ShortcutCameraUnlock", {
    Text = "Camera Unlock Button",
    Default = false,
    Callback = function(Value)
        _G.MobileShortcuts.CameraUnlock = Value
        InitializeShortcuts()
    end
})

MobileShortcutsGroupBox:AddToggle("ShortcutAutoTeleport", {
    Text = "Auto Teleport Button",
    Default = false,
    Callback = function(Value)
        _G.MobileShortcuts.AutoTeleport = Value
        InitializeShortcuts()
    end
})

MobileShortcutsGroupBox:AddToggle("ShortcutSilentAim", {
    Text = "Silent Aim Button",
    Default = false,
    Callback = function(Value)
        _G.MobileShortcuts.SilentAim = Value
        InitializeShortcuts()
    end
})

MobileShortcutsGroupBox:AddDivider()

MobileShortcutsGroupBox:AddButton({
    Text = "Reset Positions",
    Func = function()
        InitializeShortcuts()
        Library:Notify("Button positions reset!", 1)
    end,
    Tooltip = "Reset floating button positions"
})

MobileShortcutsGroupBox:AddLabel("Drag buttons to move them")

-- ========================================
-- SURVIVOR TAB (Renamed from Main Tab - LEFT SIDE)
-- ========================================

local ActionsGroupBox = Tabs.Survivor:AddLeftGroupbox("Actions", "zap")

ActionsGroupBox:AddLabel("Survivor Actions")
ActionsGroupBox:AddDivider()

-- ========================================
-- AUTO PARRY (SINGLE MODE - STRICT LOGIC)
-- ========================================

_G.AutoParryEnabled = false
_G.ParryRange = 15             -- Detection range (studs)
_G.ParryMeleeRange = 4         -- Melee range for hitbox collision (studs) 
_G.ParryFacingThreshold = 0.4  -- Facing check (dot product > 0.4)
_G.ParryShowRange = true       -- Show visual range circle
_G.ParryCircleTransparency = 0.5
_G.ParryShowOutline = true

local ParryConnection = nil
local LastParryTime = 0
local ParryDebounce = 1.5
local ParryTouchID = 8823
local RangeCircle = nil

-- ========================================
-- ESCAPE SYSTEM (Auto Dodge / Auto Teleport)
-- ========================================

_G.EscapeMode = "None"  -- "None", "Dodge", "Teleport"

-- Auto Dodge Settings (Speed Boost Only)
_G.DodgeSpeedBoost = 150      -- Speed boost percentage (100-180%)
_G.DodgeBoostDuration = 0.5   -- Boost duration (seconds)
_G.DodgeRange = 10            -- Trigger range (studs)
_G.DodgeEmergencyRange = 8    -- Emergency range with attack (studs)
local LastDodgeTime = 0
local DodgeDebounce = 2       -- Cooldown between dodge boosts

-- Auto Teleport Settings (Teleport Behind Killer)
_G.TeleportDistance = 4       -- Distance behind killer (studs)
_G.TeleportCheckCollision = true
local LastTeleportTime = 0
local TeleportCooldown = 3    -- Cooldown between teleports (seconds)

local ParryDebounce = 1.5  -- Minimum time between parry attempts (seconds)
local ParryTouchID = 8823  -- Unique touch ID for parry
local RangeCircle = nil

-- ========================================
-- PARRY BUTTON & COOLDOWN SYSTEM
-- ========================================

local ItemButtonPath = "Survivor-mob.Controls.Gui-mob.icon"

-- Get item button (Gui-mob)
local function GetItemButton()
    local current = LocalPlayer.PlayerGui
    for segment in string.gmatch(ItemButtonPath, "[^%.]+") do 
        current = current and current:FindFirstChild(segment) 
    end
    return current
end

-- Check if parry is on cooldown (read from Bar)
local function IsParryOnCooldown()
    local button = GetItemButton()
    if button then
        local bar = button:FindFirstChild("Bar")
        if bar then
            -- Bar visible and has size = on cooldown
            local onCooldown = bar.Visible and bar.Size.X.Scale > 0.05
            if onCooldown and _G.ParryDebug then
                DevLog(string.format("Parry on cooldown: %.1f%%", bar.Size.X.Scale * 100), "COOLDOWN")
            end
            return onCooldown
        end
    end
    return false
end

-- Trigger parry button (virtual input)
local function TriggerParryButton()
    if Services.UserInputService.TouchEnabled then
        -- MOBILE MODE: Virtual touch
        local button = GetItemButton()
        
        -- DEBUG: Check if button found
        if not button then
            DevLog("ERROR: Gui-mob button NOT FOUND", "DEBUG")
            return
        end
        
        DevLog(string.format("Button found: %s (Class: %s)", button.Name, button.ClassName), "DEBUG")
        
        if button:IsA("GuiObject") then
            local p = button.AbsolutePosition
            local s = button.AbsoluteSize
            local i = Services.GuiService:GetGuiInset()
            
            -- Calculate center of button
            local cx = p.X + (s.X/2) + i.X
            local cy = p.Y + (s.Y/2) + i.Y
            
            -- DEBUG: Log coordinates and button info
            DevLog(string.format("Button Pos: (%.1f, %.1f) Size: (%.1f, %.1f)", p.X, p.Y, s.X, s.Y), "DEBUG")
            DevLog(string.format("Touch coords: (%.1f, %.1f) TouchID: %d", cx, cy, ParryTouchID), "DEBUG")
            DevLog(string.format("Button Visible: %s, Active: %s", tostring(button.Visible), tostring(button.Active)), "DEBUG")
            
            local success, err = pcall(function()
                Services.VirtualInputManager:SendTouchEvent(ParryTouchID, 0, cx, cy)  -- Touch start
                DevLog("Touch START sent", "DEBUG")
                task.wait(0.05)  -- Increased from 0.01 to 0.05
                Services.VirtualInputManager:SendTouchEvent(ParryTouchID, 2, cx, cy)  -- Touch end
                DevLog("Touch END sent", "DEBUG")
            end)
            
            if success then
                DevLog("Virtual touch sent to Gui-mob button", "INPUT")
            else
                DevLog(string.format("ERROR sending touch: %s", tostring(err)), "DEBUG")
            end
        else
            DevLog(string.format("ERROR: Button is not GuiObject (Class: %s)", button.ClassName), "DEBUG")
        end
    else
        -- DESKTOP MODE: Mouse click
        pcall(function()
            mouse1click()  -- Requires executor support
            DevLog("Mouse click sent", "INPUT")
        end)
    end
end

-- Check if killer is attacking (animation detection)
-- SEPARATED: Basic Attack vs Special Skill
local function IsKillerAttacking(killerChar)
    local humanoid = killerChar:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false, nil end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false, nil end
    
    -- BASIC ATTACK ANIMATIONS (melee/lunge attacks)
    local basicAttackAnimations = {
        -- Killer (Jeff) - Basic
        "132817836308238",  -- Attack
        "129784271201071",  -- Lunge hold
        
        -- Slasher - Basic
        "139369275981139",  -- Attack
        "110355011987939",  -- Lunge hold
        
        -- Stalker (Stage 1-2) - Basic
        "133963973694098",  -- Attack
        "117042998468241",  -- Lunge hold
        
        -- Stalker (Stage 3) - Basic
        "95934119190708",   -- Attack
        "129918027564423",  -- Lunge hold
        
        -- Hidden - Basic
        "74968262036854",   -- Attack
        "113255068724446",  -- Lunge hold
        
        -- Abysswalker - Basic
        "78432063483146",   -- Attack
        "77081789642514",   -- Attack 2
        "118907603246885",  -- Lunge hold
        "80411309607666",   -- Slash
        
        -- Veil (Knife) - Basic
        "78935059863801",   -- Attack
        "122812055447896",  -- Lunge hold
        
        -- Masked (Base) - Basic
        "111920872708571",  -- Attack
        "105374834496520",  -- Lunge hold
        
        -- Masked (Tony) - Basic
        "138720291317243",  -- Attack/Lunge Tony
        
        -- Masked (Cobra) - Basic
        "130593238885843",  -- Attack Cobra
        "115244153053858",  -- Lunge Cobra
        
        -- Masked (Alex) - Basic
        "106871536134254",  -- Attack Alex
        "109402730355822",  -- Attack done Alex
        "117070354890871",  -- Lunge Alex
        
        -- Cure - Basic
        "121216847022485",  -- Attack
        "135002183282873"   -- Lunge hold
    }
    
    -- SPECIAL SKILL ANIMATIONS (abilities, powers)
    local skillAttackAnimations = {
        -- Killer (Jeff) - Skill (Frenzy)
        "82666958311998",   -- Frenzy
        
        -- Veil (Spear) - Skills
        "92098503722633",   -- Spear lunge 1
        "84093948968516",   -- Spear lunge 2
        "93136435416899",   -- Spear throw 1
        "86266790353635",   -- Spear throw 2
        "138045669415653",  -- Spear lunge OP1
        "137688077908355"   -- Spear lunge OP2
    }
    
    -- Check playing animation tracks
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        local animId = track.Animation.AnimationId
        
        -- Check basic attacks first
        for _, attackId in pairs(basicAttackAnimations) do
            if animId:match(attackId) then
                return true, "basic"  -- Return true + type
            end
        end
        
        -- Check skill attacks
        for _, skillId in pairs(skillAttackAnimations) do
            if animId:match(skillId) then
                return true, "skill"  -- Return true + type
            end
        end
    end
    
    return false, nil  -- No attack detected
end

-- ========================================
-- SIXSENSE HELPER FUNCTIONS
-- ========================================

-- Check if killer is in melee range (hitbox collision)
local function IsKillerInMeleeRange(killerRoot, myRoot)
    if not killerRoot or not myRoot then return false end
    
    local distance = (killerRoot.Position - myRoot.Position).Magnitude
    
    -- Melee range: killer must be within attack range (default 6 studs)
    local inRange = distance <= _G.ParryMeleeRange
    
    if _G.ParryDebug and inRange then
        DevLog(string.format("Melee Range: %.2f studs (threshold: %.1f)", distance, _G.ParryMeleeRange), "HITBOX")
    end
    
    return inRange
end

-- ========================================
-- NEW HELPER FUNCTIONS (OPSI A - STRICT MODE)
-- ========================================

-- Get killer name for exception checking
local function GetKillerName(killerChar)
    if not killerChar then return "Unknown" end
    
    local killerName = killerChar.Name or "Unknown"
    
    -- Check common patterns
    if killerName:match("Stalker") or killerName:match("Myers") then
        return "Myers"
    elseif killerName:match("Veil") then
        return "Veil"
    elseif killerName:match("Doctor") or killerName:match("Cure") then
        return "Doctor"
    end
    
    return killerName
end

-- Check if skill attack should be ignored (exceptions)
local function IsSkillAttackException(killerChar, attackType)
    if attackType ~= "skill" then
        return false  -- Basic attacks always allowed
    end
    
    local killerName = GetKillerName(killerChar)
    
    -- Ignore skills from: Myers, Veil, Doctor
    return killerName == "Myers" or killerName == "Veil" or killerName == "Doctor"
end

-- MAIN PARRY LOGIC - All checks must pass
local function ShouldTriggerParry(killerChar, killerRoot, myRoot)
    if not killerChar or not killerRoot or not myRoot then
        return false, "Missing parameters"
    end
    
    local distance = (killerRoot.Position - myRoot.Position).Magnitude
    
    -- CHECK 1: Detection Range (15 studs default)
    if distance > _G.ParryRange then
        return false, "Out of detection range"
    end
    
    -- CHECK 2: Melee Range (4 studs FIXED)
    if distance > _G.ParryMeleeRange then
        return false, "Not in melee range"
    end
    
    -- CHECK 3: Facing Check (killer must face survivor)
    local killerLookDir = killerRoot.CFrame.LookVector
    local dirToPlayer = (myRoot.Position - killerRoot.Position).Unit
    local faceDot = killerLookDir:Dot(dirToPlayer)
    
    if faceDot < _G.ParryFacingThreshold then
        return false, "Killer not facing survivor"
    end
    
    -- CHECK 4: Animation Check (KEY CHECK - MANDATORY)
    local isAttacking, attackType = IsKillerAttacking(killerChar)
    if not isAttacking then
        return false, "No attack animation"
    end
    
    -- CHECK 5: Skill Exception (Myers, Veil, Doctor skills ignored)
    if IsSkillAttackException(killerChar, attackType) then
        return false, "Skill attack ignored (exception)"
    end
    
    -- CHECK 6: Cooldown Check
    if IsParryOnCooldown() then
        return false, "Parry on cooldown"
    end
    
    -- CHECK 7: Equipment Check
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Parrying Dagger") then
        return false, "No dagger equipped"
    end
    
    -- ALL CHECKS PASSED
    return true, "All checks passed"
end

-- Auto Dodge Boost (Speed Only - No Direction Control)
local function AutoDodgeBoost(killerRoot, myRoot, isAttacking)
    if _G.EscapeMode ~= "Dodge" then return false end
    
    -- Check cooldown
    if (tick() - LastDodgeTime) < DodgeDebounce then
        return false
    end
    
    -- NEW: Check if survivor is in valid state (not hooked/downed)
    local isValid, reason = IsSurvivorInValidState()
    if not isValid then
        if _G.ParryDebug then
            DevLog(string.format("[Dodge] Blocked: %s", reason), "ESCAPE")
        end
        return false
    end
    
    local distance = (killerRoot.Position - myRoot.Position).Magnitude
    local boost = 0
    
    -- Emergency: Close + attacking
    if distance <= _G.DodgeEmergencyRange and isAttacking then
        boost = 180  -- Max boost (2.8x speed)
    -- Prepare: Just close
    elseif distance <= _G.DodgeRange then
        boost = _G.DodgeSpeedBoost  -- Default 150%
    end
    
    if boost > 0 then
        local char = LocalPlayer.Character
        if not char then return false end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        
        -- Apply boost
        local baseSpeed = 16
        humanoid.WalkSpeed = baseSpeed * (1 + boost/100)
        
        -- Reset after duration
        task.delay(_G.DodgeBoostDuration, function()
            if humanoid then
                humanoid.WalkSpeed = baseSpeed
            end
        end)
        
        LastDodgeTime = tick()
        DevLog(string.format("[Dodge] Speed boost %d%% for %.1fs", boost, _G.DodgeBoostDuration), "ESCAPE")
        return true
    end
    
    return false
end

-- Check if survivor is in valid state (not hooked or downed)
local function IsSurvivorInValidState()
    local char = LocalPlayer.Character
    if not char then return false end
    
    -- Check if downed (knocked)
    local isDowned = GetGameValue(char, "Downed")
    if isDowned == true then
        return false, "Survivor is downed"
    end
    
    -- Check if hooked
    local isHooked = GetGameValue(char, "Hooked")
    if isHooked == true then
        return false, "Survivor is hooked"
    end
    
    -- Check if being carried
    local isCarried = GetGameValue(char, "Carried")
    if isCarried == true then
        return false, "Survivor is being carried"
    end
    
    return true, "Valid state"
end

-- Auto Teleport Away (Behind Killer)
local function AutoTeleportAway(killerRoot, myRoot)
    if _G.EscapeMode ~= "Teleport" then return false end
    
    -- Check cooldown
    if (tick() - LastTeleportTime) < TeleportCooldown then
        return false
    end
    
    -- NEW: Check if survivor is in valid state (not hooked/downed)
    local isValid, reason = IsSurvivorInValidState()
    if not isValid then
        if _G.ParryDebug then
            DevLog(string.format("[Teleport] Blocked: %s", reason), "ESCAPE")
        end
        return false
    end
    
    -- Calculate position BEHIND killer
    local killerForward = killerRoot.CFrame.LookVector
    local behindPos = killerRoot.Position - (killerForward * _G.TeleportDistance)
    
    -- Keep Y same (don't teleport up/down)
    behindPos = Vector3.new(behindPos.X, myRoot.Position.Y, behindPos.Z)
    
    -- Collision check
    if _G.TeleportCheckCollision then
        local ray = Ray.new(killerRoot.Position, -killerForward * _G.TeleportDistance)
        local hit = Services.Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
        
        if hit then
            -- Wall detected, try right side
            local rightDir = killerForward:Cross(Vector3.new(0, 1, 0))
            behindPos = killerRoot.Position + (rightDir * _G.TeleportDistance)
            behindPos = Vector3.new(behindPos.X, myRoot.Position.Y, behindPos.Z)
        end
    end
    
    -- Teleport
    myRoot.CFrame = CFrame.new(behindPos)
    
    LastTeleportTime = tick()
    DevLog(string.format("[Teleport] Behind killer, %d studs", _G.TeleportDistance), "ESCAPE")
    return true
end

-- ========================================
-- VISUAL RANGE CIRCLE
-- ========================================

-- Create Visual Range Circle (Cylinder on ground, with transparency and outline control)
local function CreateRangeCircle()
    if RangeCircle then
        pcall(function() RangeCircle:Destroy() end)
    end
    
    pcall(function()
        -- Create Part for the circle (Cylinder flat on ground)
        local circle = Instance.new("Part")
        circle.Name = "ParryRangeCircle"
        circle.Anchored = true
        circle.CanCollide = false
        circle.Shape = Enum.PartType.Cylinder
        
        -- Set material based on outline setting
        if _G.ParryShowOutline then
            circle.Material = Enum.Material.Neon  -- Neon has visible outline
        else
            circle.Material = Enum.Material.ForceField  -- ForceField has no outline
        end
        
        circle.Transparency = _G.ParryCircleTransparency  -- Use transparency setting
        circle.Color = Color3.fromRGB(0, 255, 255)  -- Cyan default
        circle.Size = Vector3.new(0.5, _G.ParryRange * 2, _G.ParryRange * 2)  -- Height, Diameter, Diameter
        circle.TopSurface = Enum.SurfaceType.Smooth
        circle.BottomSurface = Enum.SurfaceType.Smooth
        
        circle.Parent = Services.Workspace
        RangeCircle = circle
        
        DevLog("Range circle created on ground with outline control", "VISUAL")
    end)
end

local function UpdateRangeCircle()
    if not RangeCircle or not RangeCircle.Parent then
        if _G.ParryShowRange and _G.AutoParryEnabled then
            CreateRangeCircle()
        end
        return
    end
    
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            -- Position on ground: Get root position, set Y to foot level
            local groundPos = root.Position - Vector3.new(0, 3, 0)  -- 3 studs below root = ground
            
            -- Rotate cylinder to lay flat (90 degrees on Z axis)
            RangeCircle.CFrame = CFrame.new(groundPos) * CFrame.Angles(0, 0, math.rad(90))
            
            -- Update size based on range
            RangeCircle.Size = Vector3.new(0.5, _G.ParryRange * 2, _G.ParryRange * 2)
            
            -- Update transparency
            RangeCircle.Transparency = _G.ParryCircleTransparency
            
            -- Update material based on outline setting
            if _G.ParryShowOutline then
                RangeCircle.Material = Enum.Material.Neon
            else
                RangeCircle.Material = Enum.Material.ForceField
            end
        end
    end
end

local function RemoveRangeCircle()
    if RangeCircle then
        pcall(function() RangeCircle:Destroy() end)
        RangeCircle = nil
        print("[Range Circle] Removed")
    end
end

-- Auto Parry Logic
ActionsGroupBox:AddToggle("AutoParry", {
    Text = "Auto Parry",
    Default = false,
    Tooltip = "Automatically parry killer attacks",
    Callback = function(Value)
        _G.AutoParryEnabled = Value
        
        if Value and not ParryConnection then
            print("[Auto Parry] Enabled - Mode:", _G.ParryMode)
            
            -- Create visual range if enabled
            if _G.ParryShowRange then
                CreateRangeCircle()
            end
            
            ParryConnection = Services.RunService.Heartbeat:Connect(function()
                if not _G.AutoParryEnabled then return end
                
                -- Update range circle
                if _G.ParryShowRange then
                    UpdateRangeCircle()
                end
                
                -- Character check
                local char = LocalPlayer.Character
                if not char then return end
                local myRoot = char:FindFirstChild("HumanoidRootPart")
                if not myRoot then return end
                
                -- Find killer
                for _, player in pairs(Services.Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Team then
                        local teamName = player.Team.Name
                        
                        if teamName == "Killer" then
                            local killerChar = player.Character
                            if killerChar then
                                local killerRoot = killerChar:FindFirstChild("HumanoidRootPart")
                                if killerRoot then
                                    local distance = (killerRoot.Position - myRoot.Position).Magnitude
                                    
                                    -- ESCAPE SYSTEM (runs independently from parry)
                                    if distance <= _G.ParryRange then
                                        local isAttacking = IsKillerAttacking(killerChar)
                                        
                                        -- Auto Dodge Boost (speed only)
                                        AutoDodgeBoost(killerRoot, myRoot, isAttacking)
                                        
                                        -- Auto Teleport Away (only if attacking)
                                        if isAttacking then
                                            AutoTeleportAway(killerRoot, myRoot)
                                        end
                                    end
                                    
                                    -- AUTO PARRY CHECK (strict - all must pass)
                                    local shouldParry, reason = ShouldTriggerParry(killerChar, killerRoot, myRoot)
                                    
                                    if shouldParry then
                                        -- Debounce
                                        if (tick() - LastParryTime) < ParryDebounce then
                                            return
                                        end
                                        
                                        LastParryTime = tick()
                                        
                                        -- TRIGGER PARRY
                                        TriggerParryButton()
                                        
                                        DevLog("[Parry] TRIGGERED - All checks passed", "SUCCESS")
                                        
                                        -- Visual feedback
                                        if RangeCircle then
                                            RangeCircle.Color = Color3.fromRGB(0, 255, 0)
                                            task.delay(0.2, function()
                                                if RangeCircle then
                                                    RangeCircle.Color = Color3.fromRGB(0, 255, 255)
                                                end
                                            end)
                                        end
                                        
                                        return  -- Exit after parry
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        elseif not Value and ParryConnection then
            ParryConnection:Disconnect()
            ParryConnection = nil
            RemoveRangeCircle()
            print("[Auto Parry] Disabled")
        end
    end
})

ActionsGroupBox:AddDivider()
ActionsGroupBox:AddLabel("Core Settings")

ActionsGroupBox:AddSlider("ParryRange", {
    Text = "Detection Range",
    Default = 15,
    Min = 5,
    Max = 30,
    Rounding = 0,
    Compact = false,
    Tooltip = "Range to detect killer (15 studs default)",
    Callback = function(Value)
        _G.ParryRange = Value
        if RangeCircle then
            RangeCircle.Size = Vector3.new(0.5, Value * 2, Value * 2)
        end
    end
})

ActionsGroupBox:AddDivider()
ActionsGroupBox:AddLabel("Visual Settings")

ActionsGroupBox:AddToggle("ParryShowRange", {
    Text = "Show Range Circle",
    Default = true,
    Tooltip = "Display visual range indicator (circle on ground)",
    Callback = function(Value)
        _G.ParryShowRange = Value
        
        if Value and _G.AutoParryEnabled then
            CreateRangeCircle()
        elseif not Value then
            RemoveRangeCircle()
        end
    end
}):AddColorPicker("RangeCircleColor", {
    Default = Color3.fromRGB(0, 255, 255),
    Title = "Circle Color",
    Transparency = 0.5,  -- Enable transparency
    Callback = function(Value)
        if RangeCircle then
            RangeCircle.Color = Value
        end
    end
})

-- Transparency changed callback
Options.RangeCircleColor:OnChanged(function()
    local transparency = Options.RangeCircleColor.Transparency
    _G.ParryCircleTransparency = transparency
    
    if RangeCircle then
        RangeCircle.Transparency = transparency
    end
end)

-- Outline toggle for range circle
ActionsGroupBox:AddToggle("ParryShowOutline", {
    Text = "Show Outline",
    Default = true,
    Tooltip = "Show circle outline (borders)",
    Callback = function(Value)
        _G.ParryShowOutline = Value
        
        if RangeCircle then
            -- Update circle material based on outline setting
            if Value then
                RangeCircle.Material = Enum.Material.Neon  -- Visible outline
            else
                RangeCircle.Material = Enum.Material.ForceField  -- No outline
            end
        end
    end
})

ActionsGroupBox:AddDivider()
ActionsGroupBox:AddLabel("Debug")

ActionsGroupBox:AddToggle("ParryDebug", {
    Text = "Debug Mode",
    Default = false,
    Tooltip = "Print debug info to console",
    Callback = function(Value)
        _G.ParryDebug = Value
    end
})

ActionsGroupBox:AddButton({
    Text = "Copy Debug Logs",
    Func = function()
        local logs = GetConsoleLogs()
        if setclipboard then
            setclipboard(logs)
            print("[Copy Logs] ✅ Copied to clipboard!")
        else
            print("[Copy Logs] ❌ Clipboard not supported")
            print("=== DEBUG LOGS ===")
            print(logs)
            print("==================")
        end
    end,
    Tooltip = "Copy all debug logs to clipboard"
})

-- ========================================
-- ESCAPE SYSTEM (Survivor Tab - RIGHT SIDE)
-- ========================================

local EscapeSystemGroupBox = Tabs.Survivor:AddRightGroupbox("Escape System", "zap")

EscapeSystemGroupBox:AddLabel("Choose escape method:")
EscapeSystemGroupBox:AddDivider()

-- Radio button simulation with dropdown
EscapeSystemGroupBox:AddDropdown("EscapeMode", {
    Values = {"None", "Auto Dodge Boost", "Auto Teleport Away"},
    Default = 1,
    Multi = false,
    Text = "Escape Mode",
    Tooltip = "Choose one: Speed boost or teleport (mutually exclusive)",
    Callback = function(Value)
        if Value == "Auto Dodge Boost" then
            _G.EscapeMode = "Dodge"
        elseif Value == "Auto Teleport Away" then
            _G.EscapeMode = "Teleport"
        else
            _G.EscapeMode = "None"
        end
        
        Library:Notify("Escape Mode: " .. Value, 2)
    end
})

EscapeSystemGroupBox:AddDivider()
EscapeSystemGroupBox:AddLabel("━━━ Auto Dodge Settings ━━━")

EscapeSystemGroupBox:AddSlider("DodgeSpeedBoost", {
    Text = "Speed Boost",
    Default = 150,
    Min = 100,
    Max = 180,
    Rounding = 5,
    Suffix = "%",
    Compact = false,
    Tooltip = "Speed boost when killer nearby (max 180% = 2.8x)",
    Callback = function(Value)
        _G.DodgeSpeedBoost = Value
    end
})

EscapeSystemGroupBox:AddSlider("DodgeBoostDuration", {
    Text = "Boost Duration",
    Default = 0.5,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Suffix = " sec",
    Compact = false,
    Tooltip = "How long the speed boost lasts",
    Callback = function(Value)
        _G.DodgeBoostDuration = Value
    end
})

EscapeSystemGroupBox:AddLabel("ℹ️ Trigger: 10 studs (always) / 8 studs + attack (max)")

EscapeSystemGroupBox:AddDivider()
EscapeSystemGroupBox:AddLabel("━━━ Auto Teleport Settings ━━━")

EscapeSystemGroupBox:AddSlider("TeleportDistance", {
    Text = "Teleport Distance",
    Default = 4,
    Min = 2,
    Max = 10,
    Rounding = 1,
    Suffix = " studs",
    Compact = false,
    Tooltip = "Distance behind killer after teleport",
    Callback = function(Value)
        _G.TeleportDistance = Value
    end
})

EscapeSystemGroupBox:AddToggle("TeleportCheckCollision", {
    Text = "Check Collision",
    Default = true,
    Tooltip = "If wall behind killer, teleport to side instead",
    Callback = function(Value)
        _G.TeleportCheckCollision = Value
    end
})

EscapeSystemGroupBox:AddLabel("ℹ️ Cooldown: 3 seconds")
EscapeSystemGroupBox:AddLabel("ℹ️ Teleports behind killer when attack detected")

-- ========================================
-- SKILL CHECK TAB (Survivor Tab - RIGHT SIDE)
-- ========================================

local SkillCheckGroupBox = Tabs.Survivor:AddRightGroupbox("Skill Check", "target")

-- Auto Skill Check with 2 MODES
_G.AutoSkillCheckEnabled = false
_G.SkillCheckMode = "Legit" -- Legit or Instant
local LegitConnection = nil
local InstantConnection = nil
local SpacePressed = false
local InstantDelayCompleted = false

SkillCheckGroupBox:AddDropdown("SkillCheckMode", {
    Values = {"Legit", "Instant"},
    Default = 1,
    Multi = false,
    Text = "Mode",
    Tooltip = "Legit: Natural animation + perfect timing (100%) | Instant: Locked line + auto click (100%)",
    Callback = function(Value)
        _G.SkillCheckMode = Value
        print("[Skill Check] Mode:", Value)
    end
})

SkillCheckGroupBox:AddToggle("AutoSkillCheck", {
    Text = "Auto Skill Check",
    Default = false,
    Tooltip = "Legit: Natural animation (100%) | Instant: Locked line (100%)",
    Callback = function(Value)
        _G.AutoSkillCheckEnabled = Value
        
        if Value and not _G.AutoSkillCheckInjected then
            _G.AutoSkillCheckInjected = true
            print("[Auto Skill Check] Initializing...")
            
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            local TouchID = 8822
            local ActionPath = "Survivor-mob.Controls.action.check"
            
            local function GetActionTarget()
                local current = PlayerGui
                for segment in string.gmatch(ActionPath, "[^%.]+") do 
                    current = current and current:FindFirstChild(segment) 
                end
                return current
            end

            local function TriggerButton()
                if Services.UserInputService.TouchEnabled then
                    local b = GetActionTarget()
                    if b and b:IsA("GuiObject") then
                        local p, s, i = b.AbsolutePosition, b.AbsoluteSize, Services.GuiService:GetGuiInset()
                        local cx, cy = p.X + (s.X/2) + i.X, p.Y + (s.Y/2) + i.Y
                        pcall(function() 
                            Services.VirtualInputManager:SendTouchEvent(TouchID, 0, cx, cy) 
                            task.wait(0.01) 
                            Services.VirtualInputManager:SendTouchEvent(TouchID, 2, cx, cy) 
                        end)
                    end
                else
                    pcall(function()
                        keypress(0x20)
                        task.wait(0.05)
                        keyrelease(0x20)
                    end)
                end
            end
            
            -- LEGIT MODE: Natural animation + Auto click at perfect (100%)
            local function LegitModeCheck(check, line, goal)
                if not _G.AutoSkillCheckEnabled or not check.Visible then return end
                
                local lr = line.Rotation % 360
                local gr = goal.Rotation % 360
                
                -- Perfect zone: 109° (center of 104-114 range)
                local perfectCenter = (gr + 109) % 360
                
                -- Check if Line at perfect center (±1° tolerance)
                local diff = math.abs(lr - perfectCenter)
                if diff > 180 then diff = 360 - diff end
                
                if diff <= 1 and not SpacePressed then
                    TriggerButton()
                    SpacePressed = true
                    print("[Skill Check] ⭐ Legit Perfect!")
                    
                    if LegitConnection then
                        LegitConnection:Disconnect()
                        LegitConnection = nil
                    end
                end
            end
            
            -- INSTANT MODE: Force Line + Auto Press (100% Perfect, No Animation)
            local function InstantModeCheck(check, line, goal)
                if not _G.AutoSkillCheckEnabled or not check.Visible then return end
                
                -- Step 1: ALWAYS force Line to perfect center (every frame lock)
                local goalRotation = goal.Rotation % 360
                local perfectRotation = (goalRotation + 109) % 360
                line.Rotation = perfectRotation
                
                -- Step 2: Auto press after 0.1s delay (only once)
                if not InstantDelayCompleted then
                    InstantDelayCompleted = true
                    
                    task.spawn(function()
                        task.wait(0.1)
                        
                        if check.Visible and _G.AutoSkillCheckEnabled and _G.SkillCheckMode == "Instant" then
                            TriggerButton()
                            SpacePressed = true
                            print("[Skill Check] ⚡ Instant Perfect!")
                            
                            -- Disconnect after successful press
                            task.wait(0.05)
                            if InstantConnection then
                                InstantConnection:Disconnect()
                                InstantConnection = nil
                            end
                        end
                    end)
                end
            end
            
            local function Initialize()
                task.spawn(function()
                    local prompt = PlayerGui:WaitForChild("SkillCheckPromptGui", 30)
                    if not prompt then return end
                    
                    local check = prompt:WaitForChild("Check", 10)
                    if not check then return end
                    
                    local line = check:WaitForChild("Line", 5)
                    local goal = check:WaitForChild("Goal", 5)
                    if not goal then return end
                    
                    check:GetPropertyChangedSignal("Visible"):Connect(function()
                        if not _G.AutoSkillCheckEnabled or not check.Visible then
                            -- Clean up connections
                            if LegitConnection then
                                LegitConnection:Disconnect()
                                LegitConnection = nil
                            end
                            if InstantConnection then
                                InstantConnection:Disconnect()
                                InstantConnection = nil
                            end
                            return
                        end
                        
                        if not LocalPlayer.Team or LocalPlayer.Team.Name ~= "Survivors" then return end
                        
                        -- Reset state
                        SpacePressed = false
                        InstantDelayCompleted = false
                        
                        -- Choose mode
                        if _G.SkillCheckMode == "Instant" then
                            -- INSTANT MODE: Force Line + Auto Press (100%, locked line)
                            print("[Skill Check] ⚡ Instant mode activated (locked line)")
                            
                            if InstantConnection then InstantConnection:Disconnect() end
                            
                            InstantConnection = Services.RunService.Heartbeat:Connect(function()
                                InstantModeCheck(check, line, goal)
                            end)
                            
                        else
                            -- LEGIT MODE: Natural animation + Auto click at perfect (100%)
                            print("[Skill Check] ⭐ Legit mode activated (natural animation)")
                            
                            if LegitConnection then LegitConnection:Disconnect() end
                            
                            LegitConnection = Services.RunService.Heartbeat:Connect(function()
                                LegitModeCheck(check, line, goal)
                            end)
                        end
                    end)
                    
                    print("[Auto Skill Check] Ready! Mode:", _G.SkillCheckMode)
                end)
            end
            
            Initialize()
            LocalPlayer.CharacterAdded:Connect(function() task.wait(1); Initialize() end)
        end
    end
})

-- Continue with Combat, Killer, Visuals, Settings tabs...
-- (Keeping all existing features from Fix-12)

-- ========================================
-- AIM TAB - AIMBOT (LEFT)
-- ========================================

local AimbotGroupBox = Tabs.Aim:AddLeftGroupbox("Aimbot", "crosshair")

_G.AimbotEnabled = false
_G.AimbotTargetMode = "Auto" -- Auto, Killer, Survivor
_G.AimbotHitbox = "Torso" -- Head, Torso, Legs
_G.AimbotWallCheck = true
_G.AimbotSmoothness = 5
local AimbotConnection = nil

AimbotGroupBox:AddToggle("AimbotEnabled", {
    Text = "Enable Aimbot",
    Default = false,
    Tooltip = "Automatically aim at targets",
    Callback = function(Value)
        _G.AimbotEnabled = Value
        
        if Value and not AimbotConnection then
            print("[Aimbot] Enabled")
            
            AimbotConnection = Services.RunService.Heartbeat:Connect(function()
                if not _G.AimbotEnabled then return end
                
                local camera = Services.Workspace.CurrentCamera
                local myChar = LocalPlayer.Character
                if not myChar then return end
                local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                if not myRoot then return end
                
                local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name or ""
                local targetTeam = ""
                
                -- Auto mode: determine target based on my team
                if _G.AimbotTargetMode == "Auto" then
                    if myTeam == "Survivors" then
                        targetTeam = "Killer"
                    elseif myTeam == "Killer" then
                        targetTeam = "Survivors"
                    end
                elseif _G.AimbotTargetMode == "Killer" then
                    targetTeam = "Killer"
                elseif _G.AimbotTargetMode == "Survivor" then
                    targetTeam = "Survivors"
                end
                
                -- Find closest target
                local closestTarget = nil
                local closestDist = math.huge
                
                for _, player in pairs(Services.Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Team then
                        local playerTeam = player.Team.Name
                        
                        if playerTeam == targetTeam then
                            local targetChar = player.Character
                            local hitboxPart = nil
                            
                            -- Select hitbox
                            if _G.AimbotHitbox == "Head" then
                                hitboxPart = targetChar:FindFirstChild("Head")
                            elseif _G.AimbotHitbox == "Torso" then
                                hitboxPart = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
                            elseif _G.AimbotHitbox == "Legs" then
                                hitboxPart = targetChar:FindFirstChild("Left Leg") or targetChar:FindFirstChild("LeftUpperLeg")
                            end
                            
                            if hitboxPart then
                                local dist = (hitboxPart.Position - myRoot.Position).Magnitude
                                
                                -- Wall check
                                local wallBlocked = false
                                if _G.AimbotWallCheck then
                                    local ray = Ray.new(myRoot.Position, (hitboxPart.Position - myRoot.Position).Unit * dist)
                                    local hit, pos = Services.Workspace:FindPartOnRayWithIgnoreList(ray, {myChar, targetChar})
                                    
                                    if hit then
                                        wallBlocked = true
                                    end
                                end
                                
                                if not wallBlocked and dist < closestDist then
                                    closestDist = dist
                                    closestTarget = hitboxPart
                                end
                            end
                        end
                    end
                end
                
                -- Aim at target with smoothness
                if closestTarget then
                    local targetPos = closestTarget.Position
                    local targetCFrame = CFrame.new(camera.CFrame.Position, targetPos)
                    
                    -- Apply smoothness
                    local smoothFactor = _G.AimbotSmoothness / 100
                    camera.CFrame = camera.CFrame:Lerp(targetCFrame, smoothFactor)
                end
            end)
        elseif not Value and AimbotConnection then
            AimbotConnection:Disconnect()
            AimbotConnection = nil
            print("[Aimbot] Disabled")
        end
    end
})

AimbotGroupBox:AddDropdown("AimbotTarget", {
    Values = {"Auto", "Killer", "Survivor"},
    Default = 1,
    Multi = false,
    Text = "Target Selection",
    Tooltip = "Auto: Survivor→Killer, Killer→Survivor",
    Callback = function(Value)
        _G.AimbotTargetMode = Value
        print("[Aimbot] Target:", Value)
    end
})

AimbotGroupBox:AddDropdown("AimbotHitbox", {
    Values = {"Head", "Torso", "Legs"},
    Default = 2,
    Multi = false,
    Text = "Hitbox",
    Tooltip = "Select target hitbox",
    Callback = function(Value)
        _G.AimbotHitbox = Value
        print("[Aimbot] Hitbox:", Value)
    end
})

AimbotGroupBox:AddToggle("AimbotWallCheck", {
    Text = "Wall Check",
    Default = true,
    Tooltip = "Don't aim through walls",
    Callback = function(Value)
        _G.AimbotWallCheck = Value
        print("[Aimbot] Wall Check:", Value)
    end
})

AimbotGroupBox:AddSlider("AimbotSmoothness", {
    Text = "Smoothness",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Compact = false,
    Tooltip = "Aim smoothness (1=instant, 20=very slow)",
    Callback = function(Value)
        _G.AimbotSmoothness = Value
        print("[Aimbot] Smoothness:", Value)
    end
})

-- ========================================
-- AIM TAB - SILENT AIM (RIGHT)
-- ========================================

local SilentAimGroupBox = Tabs.Aim:AddRightGroupbox("Silent Aim", "target")

-- Gun Skin Selection Dropdown
SilentAimGroupBox:AddDropdown("GunSkinSelect", {
    Values = {"Default", "EmperorGun", "AWP"},
    Default = 2,  -- EmperorGun (index starts at 1)
    Multi = false,
    Text = "Gun Skin",
    Tooltip = "Select your current gun skin",
    Callback = function(Value)
        _G.SelectedGunSkin = Value
        DevLog("Gun skin changed to: " .. Value, "SILENTAIM")
        Library:Notify("Gun Skin: " .. Value, 1)
    end
})

SilentAimGroupBox:AddDivider()

-- Silent Aim Global Variables
_G.AimOffsetX = _G.AimOffsetX or 5.0   -- Optimal: 5.0 (tested)
_G.AimOffsetY = _G.AimOffsetY or -2.5  -- Optimal: -2.5 (tested)
_G.AimOffsetZ = _G.AimOffsetZ or 0.0   -- Optimal: 0.0 (no lead)
_G.ShowSilentAimDot = false  -- Toggle for dot marker
_G.ShowSilentAimLine = false  -- Toggle for line tracer
_G.SelectedGunSkin = _G.SelectedGunSkin or "EmperorGun"  -- Default gun skin

-- Prediction Settings
_G.EnablePrediction = true   -- Auto-predict moving targets
_G.BulletSpeed = 500         -- studs/second (adjustable)
_G.PredictionMultiplier = 1.0  -- 1.0 = full prediction
_G.MinSpeedForPrediction = 2.0 -- Min speed to trigger prediction (studs/s)

-- Velocity tracking
local LastKillerPositions = {}  -- Store last positions for velocity calc
local LastKillerVelocities = {} -- Store calculated velocities

-- Gun Skin Database
local GunSkins = {
    ["Default"] = {
        type = "RightArmChild",
        childName = "gun"
    },
    ["EmperorGun"] = {
        type = "RightArmChild",
        childName = "EmperorGun"
    },
    ["AWP"] = {
        type = "ToolDirect"  -- Special case: Tool directly
    }
}

-- Visual markers
local AimDotMarker = nil
local AimLineTracer = nil
local AimLineAttachment0 = nil
local AimLineAttachment1 = nil
local AimVisualConnection = nil

-- Find killer in game
local function FindKillerForSilentAim()
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team.Name == "Killer" then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                return player
            end
        end
    end
    return nil
end

-- Get gun MODEL (Dynamic based on selected skin)
local function GetSilentAimGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    local twistOfFate = char:FindFirstChild("Twist of Fate")
    if not twistOfFate then return nil end
    
    -- Get skin configuration
    local skinConfig = GunSkins[_G.SelectedGunSkin]
    if not skinConfig then
        -- Fallback to EmperorGun if unknown skin
        skinConfig = GunSkins["EmperorGun"]
    end
    
    -- Handle different skin patterns
    if skinConfig.type == "ToolDirect" then
        -- AWP case: Use Tool directly
        DevLog("Using Tool direct (AWP pattern): " .. _G.SelectedGunSkin, "SILENTAIM")
        return twistOfFate
    elseif skinConfig.type == "RightArmChild" then
        -- Normal case: Tool → Right Arm → [SkinName]
        local rightArm = twistOfFate:FindFirstChild("Right Arm")
        if not rightArm then
            DevLog("Right Arm not found", "SILENTAIM")
            return nil
        end
        
        local gun = rightArm:FindFirstChild(skinConfig.childName)
        if gun then
            DevLog(string.format("Gun found: %s (type: %s)", skinConfig.childName, skinConfig.type), "SILENTAIM")
        else
            DevLog(string.format("Gun not found: %s", skinConfig.childName), "SILENTAIM")
        end
        return gun
    end
    
    return nil
end

-- Get gun position (for line start point)
local function GetGunPosition()
    local gun = GetSilentAimGun()
    if not gun then return nil end
    
    local mainPart = gun:FindFirstChild("main")
    if mainPart and mainPart:IsA("BasePart") then
        return mainPart.Position
    end
    
    -- Fallback: player position
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart.Position
    end
    
    return nil
end

-- Calculate target velocity
local function CalculateKillerVelocity(killerChar)
    local targetPart = killerChar:FindFirstChild("Torso") 
                    or killerChar:FindFirstChild("UpperTorso")
                    or killerChar:FindFirstChild("HumanoidRootPart")
    
    if not targetPart then return Vector3.new(0, 0, 0), 0 end
    
    local currentPos = targetPart.Position
    local currentTime = tick()
    
    -- Get last known position
    local lastData = LastKillerPositions[killerChar]
    
    if lastData then
        local deltaTime = currentTime - lastData.time
        
        -- IMPROVED: Better time window (0.05-0.3s for accuracy)
        if deltaTime > 0.05 and deltaTime < 0.3 then
            local displacement = currentPos - lastData.position
            local velocity = displacement / deltaTime
            local speed = velocity.Magnitude
            
            -- IMPROVED: Smooth velocity (reduce jitter)
            local lastVel = LastKillerVelocities[killerChar]
            if lastVel and lastVel.velocity then
                -- Smooth velocity (70% new, 30% old)
                velocity = velocity * 0.7 + lastVel.velocity * 0.3
                speed = velocity.Magnitude
            end
            
            LastKillerVelocities[killerChar] = {
                velocity = velocity,
                speed = speed,
                time = currentTime
            }
            
            -- Update last position
            LastKillerPositions[killerChar] = {
                position = currentPos,
                time = currentTime
            }
            
            return velocity, speed
        end
    end
    
    -- First time or timeout, just store position
    LastKillerPositions[killerChar] = {
        position = currentPos,
        time = currentTime
    }
    
    return Vector3.new(0, 0, 0), 0
end

-- Calculate predicted position (with automatic detection)
local function GetPredictedPosition(killer, distance)
    local killerChar = killer.Character
    if not killerChar then return nil, false end
    
    local targetPart = killerChar:FindFirstChild("Torso") 
                    or killerChar:FindFirstChild("UpperTorso")
                    or killerChar:FindFirstChild("HumanoidRootPart")
    
    if not targetPart then return nil, false end
    
    local currentPos = targetPart.Position
    
    -- Check if prediction is enabled
    if not _G.EnablePrediction then
        return currentPos, false
    end
    
    -- Calculate velocity
    local velocity, speed = CalculateKillerVelocity(killerChar)
    
    -- Check if target is moving enough to predict
    if speed < _G.MinSpeedForPrediction then
        -- Target is static or slow, no prediction needed
        return currentPos, false
    end
    
    -- IMPROVED: Better prediction algorithm
    -- 1. Calculate bullet travel time based on distance
    local bulletSpeed = math.max(_G.BulletSpeed, 50)  -- Minimum 50 to avoid division by zero
    local timeToTarget = distance / bulletSpeed
    
    -- 2. Calculate raw prediction (where target will be)
    local rawPrediction = velocity * timeToTarget
    
    -- 3. Apply multiplier for fine-tuning
    local scaledPrediction = rawPrediction * _G.PredictionMultiplier
    
    -- 4. Distance-based scaling (reduce prediction at long range)
    local distanceScale = math.clamp(1 - (distance / 500), 0.3, 1)  -- Scale down at >500 studs
    local finalPrediction = scaledPrediction * distanceScale
    
    -- 5. Calculate final position
    local predictedPos = currentPos + finalPrediction
    
    -- Log prediction
    DevLog(string.format("Prediction: Speed=%.1f studs/s, Lead=%.2f studs, Time=%.3fs, DistScale=%.2f",
        speed, finalPrediction.Magnitude, timeToTarget, distanceScale), "SILENTAIM")
    
    return predictedPos, true  -- Return predicted position + flag
end

-- Get aim target position (with offset and optional prediction)
local function GetAimTargetPosition(killer)
    local killerChar = killer.Character
    if not killerChar then
        return nil
    end
    
    -- Calculate distance first (needed for prediction)
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    -- IMPROVED: Better target part priority (Torso is best hitbox)
    local targetPart = killerChar:FindFirstChild("Torso")  -- R6 (best)
    if not targetPart then
        targetPart = killerChar:FindFirstChild("UpperTorso")  -- R15 (good)
    end
    if not targetPart then
        targetPart = killerChar:FindFirstChild("HumanoidRootPart")  -- Fallback
    end
    
    if not targetPart then
        return nil
    end
    
    local myPos = myChar.HumanoidRootPart.Position
    local distance = (targetPart.Position - myPos).Magnitude
    
    -- Get predicted position (or current if not moving)
    local targetPos, wasPredicted = GetPredictedPosition(killer, distance)
    if not targetPos then
        return nil
    end
    
    -- IMPROVED: Apply offsets in world space (more consistent)
    -- Convert offsets to CFrame for proper application
    local offset = Vector3.new(_G.AimOffsetX, _G.AimOffsetY, _G.AimOffsetZ)
    local aimPos = targetPos + offset
    
    -- IMPROVED: Add hitbox size compensation for better accuracy
    if targetPart.Size then
        local hitboxCompensation = targetPart.Size / 2
        -- Apply small offset toward center for better hit rate
        aimPos = aimPos + Vector3.new(0, hitboxCompensation.Y * 0.3, 0)
    end
    
    -- Log
    if wasPredicted then
        DevLog("Using PREDICTED position (target moving)", "SILENTAIM")
    else
        DevLog("Using CURRENT position (target static)", "SILENTAIM")
    end
    
    return aimPos
end

-- Calculate direction with priority target selection (Tester method + offset)
local function CalculateSilentAimDirection(killer)
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local targetPos = GetAimTargetPosition(killer)
    if not targetPos then
        return nil
    end
    
    local myPos = myChar.HumanoidRootPart.Position
    
    -- Calculate direction (normalized)
    local direction = (targetPos - myPos).Unit
    
    local killerChar = killer.Character
    local targetPart = killerChar:FindFirstChild("Torso") 
                    or killerChar:FindFirstChild("UpperTorso")
                    or killerChar:FindFirstChild("HumanoidRootPart")
    
    DevLog(string.format("Target: %s (%s) | Offset: (%.1f, %.1f, %.1f)", 
        killer.Name, targetPart.Name, _G.AimOffsetX, _G.AimOffsetY, _G.AimOffsetZ), "SILENTAIM")
    
    return direction
end

-- Create visual aim dot marker
local function CreateAimDotMarker()
    if AimDotMarker then
        pcall(function() AimDotMarker:Destroy() end)
    end
    
    pcall(function()
        local dot = Instance.new("Part")
        dot.Name = "SilentAimDot"
        dot.Anchored = true
        dot.CanCollide = false
        dot.Shape = Enum.PartType.Ball
        dot.Material = Enum.Material.Neon
        dot.Color = Color3.fromRGB(0, 255, 0)  -- Green
        dot.Size = Vector3.new(0.5, 0.5, 0.5)  -- Small sphere
        dot.Transparency = 0.3
        dot.TopSurface = Enum.SurfaceType.Smooth
        dot.BottomSurface = Enum.SurfaceType.Smooth
        dot.Parent = Services.Workspace
        
        AimDotMarker = dot
        DevLog("Aim dot marker created", "SILENTAIM")
    end)
end

-- Create visual aim line tracer
local function CreateAimLineTracer()
    if AimLineTracer then
        pcall(function() AimLineTracer:Destroy() end)
    end
    if AimLineAttachment0 then
        pcall(function() AimLineAttachment0:Destroy() end)
    end
    if AimLineAttachment1 then
        pcall(function() AimLineAttachment1:Destroy() end)
    end
    
    pcall(function()
        -- Create invisible parts for attachments
        local startPart = Instance.new("Part")
        startPart.Name = "LineStart"
        startPart.Anchored = true
        startPart.CanCollide = false
        startPart.Size = Vector3.new(0.1, 0.1, 0.1)
        startPart.Transparency = 1
        startPart.Parent = Services.Workspace
        
        local endPart = Instance.new("Part")
        endPart.Name = "LineEnd"
        endPart.Anchored = true
        endPart.CanCollide = false
        endPart.Size = Vector3.new(0.1, 0.1, 0.1)
        endPart.Transparency = 1
        endPart.Parent = Services.Workspace
        
        -- Create attachments
        local att0 = Instance.new("Attachment")
        att0.Parent = startPart
        AimLineAttachment0 = att0
        
        local att1 = Instance.new("Attachment")
        att1.Parent = endPart
        AimLineAttachment1 = att1
        
        -- Create beam (line)
        local beam = Instance.new("Beam")
        beam.Name = "SilentAimLine"
        beam.Attachment0 = att0
        beam.Attachment1 = att1
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))  -- Red line
        beam.Width0 = 0.2
        beam.Width1 = 0.2
        beam.FaceCamera = true
        beam.Transparency = NumberSequence.new(0.3)
        beam.Parent = startPart
        
        AimLineTracer = beam
        DevLog("Aim line tracer created", "SILENTAIM")
    end)
end

-- Update aim visuals (dot + line) - Called every frame
local function UpdateAimVisuals()
    local killer = FindKillerForSilentAim()
    
    if not killer then
        -- Hide visuals if no killer found
        if AimDotMarker and AimDotMarker.Parent then
            AimDotMarker.Transparency = 1
        end
        return
    end
    
    -- Update DOT
    if _G.ShowSilentAimDot and AimDotMarker and AimDotMarker.Parent then
        local targetPos = GetAimTargetPosition(killer)
        if targetPos then
            AimDotMarker.Position = targetPos
            AimDotMarker.Transparency = 0.3  -- Show dot
            
            -- Change color based on distance
            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local distance = (targetPos - myChar.HumanoidRootPart.Position).Magnitude
                
                -- Green (close) → Yellow (medium) → Red (far)
                if distance < 50 then
                    AimDotMarker.Color = Color3.fromRGB(0, 255, 0)  -- Green
                elseif distance < 100 then
                    AimDotMarker.Color = Color3.fromRGB(255, 255, 0)  -- Yellow
                else
                    AimDotMarker.Color = Color3.fromRGB(255, 0, 0)  -- Red
                end
            end
        else
            AimDotMarker.Transparency = 1  -- Hide if no target
        end
    end
    
    -- Update LINE
    if _G.ShowSilentAimLine and AimLineTracer and AimLineTracer.Parent then
        local gunPos = GetGunPosition()
        local targetPos = GetAimTargetPosition(killer)
        
        if gunPos and targetPos then
            -- Update start point (gun position)
            if AimLineAttachment0 and AimLineAttachment0.Parent then
                AimLineAttachment0.Parent.Position = gunPos
            end
            
            -- Update end point (target position with offset applied)
            if AimLineAttachment1 and AimLineAttachment1.Parent then
                AimLineAttachment1.Parent.Position = targetPos
            end
            
            -- Make line visible
            if AimLineTracer then
                AimLineTracer.Transparency = NumberSequence.new(0.3)
            end
        else
            -- Hide line if no valid positions
            if AimLineTracer then
                AimLineTracer.Transparency = NumberSequence.new(1)
            end
        end
    end
end

-- Remove aim dot marker
local function RemoveAimDotMarker()
    if AimDotMarker then
        pcall(function() AimDotMarker:Destroy() end)
        AimDotMarker = nil
        DevLog("Aim dot marker removed", "SILENTAIM")
    end
end

-- Remove aim line tracer
local function RemoveAimLineTracer()
    if AimLineTracer then
        pcall(function() AimLineTracer:Destroy() end)
        AimLineTracer = nil
    end
    
    if AimLineAttachment0 and AimLineAttachment0.Parent then
        pcall(function() AimLineAttachment0.Parent:Destroy() end)
        AimLineAttachment0 = nil
    end
    
    if AimLineAttachment1 and AimLineAttachment1.Parent then
        pcall(function() AimLineAttachment1.Parent:Destroy() end)
        AimLineAttachment1 = nil
    end
    
    DevLog("Aim line tracer removed", "SILENTAIM")
end

-- Remove all aim visuals
local function RemoveAllAimVisuals()
    RemoveAimDotMarker()
    RemoveAimLineTracer()
    
    if AimVisualConnection then
        AimVisualConnection:Disconnect()
        AimVisualConnection = nil
    end
end

-- Execute Silent Aim
_G.ExecuteSilentAim = function()
    local success, err = pcall(function()
        -- Step 1: Check gun
        local gun = GetSilentAimGun()
        if not gun then
            Library:Notify("❌ Twist of Fate not equipped", 2)
            DevLog("Twist of Fate not equipped", "SILENTAIM")
            return
        end
        
        -- Step 2: Find killer
        local killer = FindKillerForSilentAim()
        if not killer then
            Library:Notify("❌ No Killer found", 2)
            DevLog("No killer in game", "SILENTAIM")
            return
        end
        
        -- Step 3: Calculate direction with priority target
        local direction = CalculateSilentAimDirection(killer)
        if not direction then
            Library:Notify("❌ Cannot calculate aim", 2)
            DevLog("Failed to calculate direction", "SILENTAIM")
            return
        end
        
        -- Step 4: Get fire remote
        local fireRemote = Services.ReplicatedStorage:FindFirstChild("Remotes")
        if fireRemote then fireRemote = fireRemote:FindFirstChild("Items") end
        if fireRemote then fireRemote = fireRemote:FindFirstChild("Twist of Fate") end
        if fireRemote then fireRemote = fireRemote:FindFirstChild("Fire") end
        
        if not fireRemote then
            Library:Notify("❌ Fire remote not found", 2)
            DevLog("Remote not found", "SILENTAIM")
            return
        end
        
        -- Step 5: Fire gun with silent aim
        local targetPart = killer.Character:FindFirstChild("Torso") 
                        or killer.Character:FindFirstChild("UpperTorso")
                        or killer.Character:FindFirstChild("HumanoidRootPart")
        
        local distance = (targetPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        
        DevLog(string.format("Firing at: %s (%.1f studs, target: %s)", 
            killer.Name, distance, targetPart.Name), "SILENTAIM")
        
        fireRemote:FireServer(gun, direction)
        
        Library:Notify(string.format("🎯 Fired! (%.1f, %.1f, %.1f)", 
            _G.AimOffsetX, _G.AimOffsetY, _G.AimOffsetZ), 1.5)
        DevLog("Silent Aim fired successfully", "SILENTAIM")
    end)
    
    if not success then
        warn("[Silent Aim] Error:", err)
        Library:Notify("Silent Aim Failed: " .. tostring(err), 2)
        return false
    else
        return true
    end
end

SilentAimGroupBox:AddButton({
    Text = "🎯 Fire Silent Aim",
    Func = function()
        _G.ExecuteSilentAim()
    end,
    Tooltip = "Fire gun at Killer with smart targeting"
})

SilentAimGroupBox:AddDivider()

SilentAimGroupBox:AddToggle("ShowAimDot", {
    Text = "Show Aim Dot",
    Default = false,
    Tooltip = "Display sphere marker at aim point",
    Callback = function(Value)
        _G.ShowSilentAimDot = Value
        
        if Value then
            CreateAimDotMarker()
            
            -- Start update loop if not already running
            if not AimVisualConnection then
                AimVisualConnection = Services.RunService.Heartbeat:Connect(function()
                    UpdateAimVisuals()
                end)
            end
            
            DevLog("Aim dot enabled", "SILENTAIM")
        else
            RemoveAimDotMarker()
            
            -- Stop loop if both disabled
            if not _G.ShowSilentAimLine and AimVisualConnection then
                AimVisualConnection:Disconnect()
                AimVisualConnection = nil
            end
            
            DevLog("Aim dot disabled", "SILENTAIM")
        end
    end
}):AddColorPicker("AimDotColor", {
    Default = Color3.fromRGB(0, 255, 0),
    Title = "Dot Color",
    Transparency = 0.3,
    Callback = function(Value)
        if AimDotMarker then
            AimDotMarker.Color = Value
        end
    end
})

-- Dot transparency changed callback
Options.AimDotColor:OnChanged(function()
    local transparency = Options.AimDotColor.Transparency
    
    if AimDotMarker then
        AimDotMarker.Transparency = transparency
    end
end)

SilentAimGroupBox:AddToggle("ShowAimLine", {
    Text = "Show Aim Line",
    Default = false,
    Tooltip = "Display line from gun to aim point",
    Callback = function(Value)
        _G.ShowSilentAimLine = Value
        
        if Value then
            CreateAimLineTracer()
            
            -- Start update loop if not already running
            if not AimVisualConnection then
                AimVisualConnection = Services.RunService.Heartbeat:Connect(function()
                    UpdateAimVisuals()
                end)
            end
            
            DevLog("Aim line enabled", "SILENTAIM")
        else
            RemoveAimLineTracer()
            
            -- Stop loop if both disabled
            if not _G.ShowSilentAimDot and AimVisualConnection then
                AimVisualConnection:Disconnect()
                AimVisualConnection = nil
            end
            
            DevLog("Aim line disabled", "SILENTAIM")
        end
    end
}):AddColorPicker("AimLineColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Line Color",
    Transparency = 0.3,
    Callback = function(Value)
        if AimLineTracer then
            AimLineTracer.Color = ColorSequence.new(Value)
        end
    end
})

-- Line transparency changed callback
Options.AimLineColor:OnChanged(function()
    local transparency = Options.AimLineColor.Transparency
    
    if AimLineTracer then
        AimLineTracer.Transparency = NumberSequence.new(transparency)
    end
end)

SilentAimGroupBox:AddDivider()

SilentAimGroupBox:AddSlider("SilentAimOffsetX", {
    Text = "X Offset (Left/Right)",
    Default = 5.0,
    Min = -10,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        _G.AimOffsetX = Value
        DevLog(string.format("Offset X: %.1f", Value), "SILENTAIM")
    end
})

SilentAimGroupBox:AddSlider("SilentAimOffsetY", {
    Text = "Y Offset (Up/Down)",
    Default = -2.5,
    Min = -10,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        _G.AimOffsetY = Value
        DevLog(string.format("Offset Y: %.1f", Value), "SILENTAIM")
    end
})

SilentAimGroupBox:AddSlider("SilentAimOffsetZ", {
    Text = "Z Offset (Forward/Back)",
    Default = 0.0,
    Min = -10,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        _G.AimOffsetZ = Value
        DevLog(string.format("Offset Z: %.1f", Value), "SILENTAIM")
    end
})

SilentAimGroupBox:AddDivider()

SilentAimGroupBox:AddButton({
    Text = "Reset to Optimal",
    Func = function()
        _G.AimOffsetX = 5.0
        _G.AimOffsetY = -2.5
        _G.AimOffsetZ = 0.0
        
        -- Update sliders
        Options.SilentAimOffsetX:SetValue(5.0)
        Options.SilentAimOffsetY:SetValue(-2.5)
        Options.SilentAimOffsetZ:SetValue(0.0)
        
        Library:Notify("Reset to optimal (5.0, -2.5, 0.0)", 2)
        DevLog("Offset reset to optimal values", "SILENTAIM")
    end,
    Tooltip = "Reset to tested optimal values (static targets)"
})

SilentAimGroupBox:AddDivider()

SilentAimGroupBox:AddToggle("EnablePrediction", {
    Text = "Auto-Predict Movement",
    Default = true,
    Tooltip = "Automatically lead shot when target is moving",
    Callback = function(Value)
        _G.EnablePrediction = Value
        DevLog("Prediction: " .. (Value and "ON" or "OFF"), "SILENTAIM")
        Library:Notify("Prediction: " .. (Value and "ON" or "OFF"), 1)
    end
})

SilentAimGroupBox:AddSlider("BulletSpeed", {
    Text = "Bullet Speed",
    Default = 500,
    Min = 100,
    Max = 2000,
    Rounding = 50,
    Compact = false,
    Callback = function(Value)
        _G.BulletSpeed = Value
        DevLog(string.format("Bullet Speed: %d studs/s", Value), "SILENTAIM")
    end
})

SilentAimGroupBox:AddSlider("PredictionMultiplier", {
    Text = "Prediction Strength",
    Default = 10,
    Min = 0,
    Max = 20,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        _G.PredictionMultiplier = Value / 10
        DevLog(string.format("Prediction: %.1fx", _G.PredictionMultiplier), "SILENTAIM")
    end
})

-- ========================================
-- KILLER TAB
-- ========================================

local KillerPowersGroupBox = Tabs.Killer:AddLeftGroupbox("Powers", "zap")

_G.AutoAttackEnabled = false

KillerPowersGroupBox:AddToggle("AutoAttack", {
    Text = "Auto Attack",
    Default = false,
    Tooltip = "Automatically attack nearby survivors (10 studs)",
    Callback = function(Value)
        _G.AutoAttackEnabled = Value
        
        if Value and not _G.AutoAttackConn then
            print("[Auto Attack] On")
            
            _G.AutoAttackConn = Services.RunService.Heartbeat:Connect(function()
                if not _G.AutoAttackEnabled then return end
                
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    if not LocalPlayer.Team or LocalPlayer.Team.Name ~= "Killer" then return end
                    
                    local closestTarget, closestDist = nil, 10
                    
                    for _, player in pairs(Services.Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" then
                            local targetChar = player.Character
                            if targetChar then
                                local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
                                if targetHrp then
                                    local dist = (targetHrp.Position - hrp.Position).Magnitude
                                    if dist < closestDist then
                                        closestDist = dist
                                        closestTarget = player
                                    end
                                end
                            end
                        end
                    end
                    
                    if closestTarget then
                        local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
                        if remotes then
                            local attacks = remotes:FindFirstChild("Attacks")
                            if attacks then
                                local hitRemote = attacks:FindFirstChild("hit")
                                if hitRemote then
                                    hitRemote:FireServer(closestTarget, 100)
                                end
                            end
                        end
                    end
                end)
            end)
        elseif not Value and _G.AutoAttackConn then
            _G.AutoAttackConn:Disconnect()
            _G.AutoAttackConn = nil
            print("[Auto Attack] Off")
        end
    end
})

-- ========================================
-- FAKE ATTACK SYSTEM (Fix-26) - NO GETGENV
-- ========================================

local FakeAttackGroupBox = Tabs.Killer:AddLeftGroupbox("Invisible Attack", "eye-off")

FakeAttackGroupBox:AddLabel("Trigger Auto-Parry WITHOUT Visual")
FakeAttackGroupBox:AddDivider()
FakeAttackGroupBox:AddLabel("Play attack animation invisibly")
FakeAttackGroupBox:AddLabel("Enemy auto-parry triggers (wasted)")
FakeAttackGroupBox:AddLabel("Then attack for real!")

-- OLD: ExecuteFakeAttack (removed - doesn't work)
-- Use _G instead of _G
_G.ExecuteFakeAttack = function()
    local success, err = pcall(function()
        local char = LocalPlayer.Character
        if not char then error("Character not found") end
        if not _G.IsKiller() then error("Must be Killer team") end
        
        local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then error("Remotes not found") end
        local attacks = remotes:FindFirstChild("Attacks")
        if not attacks then error("Attacks not found") end
        local hitRemote = attacks:FindFirstChild("hit")
        if not hitRemote then error("hit remote not found") end
        
        local target = nil
        local closestDistance = math.huge
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        
        if myRoot then
            for _, player in pairs(Services.Players:GetPlayers()) do
                if player ~= LocalPlayer and _G.IsSurvivor() then
                    local targetChar = player.Character
                    if targetChar then
                        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            local distance = (targetRoot.Position - myRoot.Position).Magnitude
                            if distance < closestDistance and distance <= 30 then
                                closestDistance = distance
                                target = targetChar
                            end
                        end
                    end
                end
            end
        end
        
        hitRemote:FireServer(target, 0)
        Library:Notify("Fake Attack Sent!", 1)
        print("[Fake Attack] Sent to target")
    end)
    
    if not success then
        warn("[Fake Attack] Failed:", err)
        Library:Notify("Fake Attack Failed: " .. tostring(err), 2)
        return false
    else
        print("[Fake Attack] Success!")
        return true
    end
end

-- Killer Attack Animation Database
local KillerAttackAnimations = {
    -- Basic Killers
    ["Killer"] = "132817836308238",      -- Jeff basic attack
    ["Slasher"] = "139369275981139",     -- Slasher attack
    ["Hidden"] = "74968262036854",       -- Hidden attack
    ["Abysswalker"] = "78432063483146",  -- Abysswalker attack
    ["Cure"] = "121216847022485",        -- Cure attack
    
    -- Stalker (Stage detection needed)
    ["Stalker"] = "133963973694098",     -- Stalker Stage 1-2
    ["Stalker3"] = "95934119190708",     -- Stalker Stage 3 (if detectable)
    
    -- Veil (Mode detection needed)
    ["Veil"] = "78935059863801",         -- Veil knife mode (default)
    ["VeilSpear"] = "92098503722633",    -- Veil spear mode (if detectable)
    
    -- Masked (Base + Variants)
    ["Masked"] = "111920872708571",      -- Masked base
    ["MaskedTony"] = "138720291317243",  -- Tony variant
    ["MaskedCobra"] = "130593238885843", -- Cobra variant
    ["MaskedAlex"] = "106871536134254",  -- Alex variant
}

-- Attack Animation Only (no remote fire)
_G.ExecuteAttackAnimation = function()
    local success, err = pcall(function()
        -- Step 1: Check character
        local char = LocalPlayer.Character
        if not char then error("Character not found") end
        
        -- Step 2: Check team
        if not _G.IsKiller() then error("Must be Killer team") end
        
        -- Step 3: Check humanoid
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then error("Humanoid not found") end
        
        -- Step 4: Check animator
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then error("Animator not found") end
        
        -- Step 5: Get killer name via GetGameValue
        local selectedKiller = GetGameValue(LocalPlayer, "SelectedKiller")
        if not selectedKiller then error("Could not detect killer type") end
        
        print("[Attack Anim] Detected killer:", selectedKiller)
        
        -- Step 6: Match killer name with animation database
        local animId = KillerAttackAnimations[selectedKiller]
        
        -- Special handling for Masked variants
        if not animId and selectedKiller:lower():find("masked") then
            -- Try to detect mask type
            local maskType = GetGameValue(LocalPlayer, "Mask") or GetGameValue(char, "Mask")
            if maskType then
                print("[Attack Anim] Detected mask:", maskType)
                -- Try variant names: MaskedTony, MaskedCobra, MaskedAlex
                local variantKey = "Masked" .. tostring(maskType)
                animId = KillerAttackAnimations[variantKey] or KillerAttackAnimations["Masked"]
            else
                animId = KillerAttackAnimations["Masked"] -- Default masked
            end
        end
        
        if not animId then
            error("Killer '" .. tostring(selectedKiller) .. "' not in animation database")
        end
        
        print("[Attack Anim] Using animation ID:", animId)
        
        -- Step 7: Create animation instance
        local attackAnim = Instance.new("Animation")
        attackAnim.AnimationId = "rbxassetid://" .. animId
        
        -- Step 8: Load and play animation
        local track = animator:LoadAnimation(attackAnim)
        track:Play()
        
        Library:Notify("Attack Animation Played!", 1)
        print("[Attack Anim] Success! Killer:", selectedKiller)
    end)
    
    if not success then
        warn("[Attack Anim] Failed:", err)
        Library:Notify("Attack Anim Failed: " .. tostring(err), 2)
        return false
    else
        return true
    end
end

-- Invisible Attack (Trigger auto-parry WITHOUT visual)
_G.ExecuteInvisibleAttack = function()
    local success, err = pcall(function()
        -- Step 1: Check character
        local char = LocalPlayer.Character
        if not char then error("Character not found") end
        
        -- Step 2: Check humanoid
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then error("Humanoid not found") end
        
        -- Step 3: Check animator
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then error("Animator not found") end
        
        -- Step 4: Team check & warning
        local currentTeam = _G.GetPlayerTeam()
        if not _G.IsKiller() then
            Library:Notify("⚠️ Not Killer - May not trigger auto-parry", 2)
            print("[Invisible Attack] WARNING: Current team:", currentTeam)
            print("[Invisible Attack] Auto-parry scripts may filter by team (Killer only)")
            print("[Invisible Attack] Animation will play but may be ignored by enemy scripts")
        else
            print("[Invisible Attack] Team check: Killer ✅")
        end
        
        -- Step 5: Hardcoded Abysswalker attack animation ID
        local animId = "78432063483146"
        
        print("[Invisible Attack] Using Abysswalker animation ID:", animId)
        print("[Invisible Attack] Current team:", currentTeam)
        
        -- Step 6: Create animation instance
        local attackAnim = Instance.new("Animation")
        attackAnim.AnimationId = "rbxassetid://" .. animId
        
        -- Step 7: Load and play animation
        local track = animator:LoadAnimation(attackAnim)
        track:Play()
        
        -- Step 8: MAKE IT INVISIBLE
        -- Method 1: Set weight to 0 (preferred)
        track:AdjustWeight(0)
        
        -- Method 2: Stop immediately (backup)
        task.wait(0.01)
        track:Stop()
        
        if _G.IsKiller() then
            Library:Notify("Invisible Attack Triggered!", 1)
        else
            Library:Notify("Attack Played (Survivor mode)", 1.5)
        end
        
        print("[Invisible Attack] Success! Animation triggered but NOT visible")
        if not _G.IsKiller() then
            print("[Invisible Attack] Note: Enemy auto-parry may not trigger (team filter)")
        else
            print("[Invisible Attack] Enemy auto-parry should trigger")
        end
    end)
    
    if not success then
        warn("[Invisible Attack] Failed:", err)
        Library:Notify("Invisible Attack Failed: " .. tostring(err), 2)
        return false
    else
        return true
    end
end

FakeAttackGroupBox:AddButton({
    Text = "Trigger Invisible Attack",
    Func = function()
        _G.ExecuteInvisibleAttack()
    end,
    Tooltip = "Play attack animation invisibly to trigger enemy auto-parry"
})

FakeAttackGroupBox:AddDivider()
FakeAttackGroupBox:AddLabel("Works like Attack Anim but invisible")
FakeAttackGroupBox:AddLabel("Use shortcut 'Attack' button for quick access!")

-- ========================================
-- KILLER ACTIONS
-- ========================================

local KillerActionsGroupBox = Tabs.Killer:AddRightGroupbox("Actions", "crosshair")

KillerActionsGroupBox:AddButton({
    Text = "Instant Mori [WIP]",
    Func = function()
        print("[Instant Mori] WIP")
    end,
    Tooltip = "Coming soon..."
})

-- ========================================
-- VISUALS TAB - ESP SYSTEM FROM MELONZ
-- ========================================

-- ESP VARIABLES (Billboard only, Chams handled separately)
_G.ESP_Survivor_Name = false
_G.ESP_Killer_Name = false
_G.ESP_Generator = false
_G.ESP_Pallet = false
_G.ESP_Gate = false
_G.ESP_Hook = false
_G.ESP_ShowSpeed = false  -- NEW: Show Speed toggle

-- ESP COLORS (From Melonz)
local ESP_Colors = {
    Killer = Color3.fromRGB(255, 93, 108),
    Survivor = Color3.fromRGB(0, 255, 34),
    Generator = Color3.fromRGB(200, 100, 0),
    Gate = Color3.fromRGB(255, 255, 255),
    Pallet = Color3.fromRGB(53, 189, 166),
    Hook = Color3.fromRGB(252, 116, 116)
}

-- KILLER TYPES (From Melonz)
local KillerTypes = {
    Abysswalker = "ABYSSWALKER",
    Hidden = "HIDDEN",
    Killer = "THE KILLER",
    Masked = "PALA AYAM",
    Stalker = "STALKER",
    Veil = "VEIL",
    Slasher = "SLASHER"
}

local KillerColors = {
    Abysswalker = Color3.fromRGB(110, 20, 255),
    Hidden = Color3.fromRGB(170, 170, 170),
    Killer = Color3.fromRGB(255, 40, 40),
    Masked = Color3.fromRGB(255, 90, 20),
    Stalker = Color3.fromRGB(255, 0, 140),
    Veil = Color3.fromRGB(0, 140, 255),
    Slasher = Color3.fromRGB(180, 0, 255)
}

-- STORAGE
local PlayerESPData = {}
local PlayerPositions = {}  -- For speed calculation
local CachedGenerators = {}  -- OPTIMIZATION: Cache generator list
local ESPConnection = nil
local LastESPUpdate = 0
local LastGeneratorScan = 0  -- OPTIMIZATION: Track generator scan timing
local ESPUpdateRate = 0.1  -- Update every 0.1s (10 FPS for ESP)
local GeneratorScanRate = 2  -- Scan for generators every 2s
local ESPMaxDistance = 500  -- Only show ESP within 500 studs

-- HELPER: Get Game Value (From Melonz)
local function GetGameValue(obj, name)
    if not obj then return nil end
    
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    
    local child = obj:FindFirstChild(name)
    if child and child:IsA("ValueBase") then
        return child.Value
    end
    
    return nil
end

-- HELPER: Check Boolean Value
local function CheckBool(value)
    return value == true or (type(value) == "number" and value > 0)
end

-- HELPER: Calculate Speed (From ESP Info)
local function CalculatePlayerSpeed(player, rootPart)
    if not _G.ESP_ShowSpeed then return 0 end
    if not player or not rootPart then return 0 end
    
    local speed = 0
    
    if not PlayerPositions[player] then
        PlayerPositions[player] = {
            LastPosition = rootPart.Position,
            LastTime = tick(),
            LastSpeed = 0
        }
        return 0  -- First frame, no speed yet
    else
        local data = PlayerPositions[player]
        local currentTime = tick()
        local deltaTime = currentTime - data.LastTime
        
        -- Recalculate speed every 0.2s
        if deltaTime >= 0.2 then
            local currentPos = rootPart.Position
            local distance = (currentPos - data.LastPosition).Magnitude
            speed = math.floor(distance / deltaTime)
            
            data.LastPosition = currentPos
            data.LastTime = currentTime
            data.LastSpeed = speed
        else
            speed = data.LastSpeed or 0
        end
    end
    
    return speed
end

-- UPDATE PLAYER ESP (From Melonz - Adapted)
local function UpdatePlayerESP(player, isKiller)
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if not root or not humanoid or humanoid.Health <= 0 then
        -- Remove ESP
        local billboard = root and root:FindFirstChild("TagESP")
        if billboard then billboard:Destroy() end
        PlayerESPData[player.UserId] = nil
        return
    end
    
    -- Calculate distance
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local distance = math.floor((root.Position - myRoot.Position).Magnitude)
    local color = isKiller and ESP_Colors.Killer or ESP_Colors.Survivor
    local status = ""
    local statusText = ""
    
    if isKiller then
        -- KILLER: Detect type
        local killerType = char:GetAttribute("CachedMask") 
                        or char:GetAttribute("KillerType") 
                        or char:GetAttribute("SelectedKiller") 
                        or GetGameValue(char, "SelectedKiller") 
                        or GetGameValue(player, "SelectedKiller") 
                        or GetGameValue(char, "Mask") 
                        or GetGameValue(player, "Mask") 
                        or char.Name
        
        if killerType then
            char:SetAttribute("CachedMask", killerType)
            status = KillerTypes[killerType] or "KILLER"
            color = KillerColors[killerType] or color
        else
            status = "KILLER"
        end
        
        statusText = string.format('<font color="#DDDDDD">%dm</font> | <font color="#%s">[%s]</font>', 
            distance, color:ToHex(), string.upper(status))
    else
        -- SURVIVOR: Detect status
        local isHooked = CheckBool(GetGameValue(char, "IsHooked")) or CheckBool(GetGameValue(player, "IsHooked"))
        local isCarried = CheckBool(GetGameValue(char, "Carried")) or CheckBool(GetGameValue(char, "IsCarried")) 
                       or CheckBool(GetGameValue(char, "Grabbed")) or CheckBool(GetGameValue(player, "Carried"))
        local isKnocked = CheckBool(GetGameValue(char, "Knocked")) or CheckBool(GetGameValue(char, "IsKnocked"))
        
        if isHooked then
            color = Color3.fromRGB(255, 75, 147)
            status = "HOOKED"
        elseif isCarried then
            color = Color3.fromRGB(200, 75, 255)
            status = "CARRIED"
        elseif isKnocked then
            color = Color3.fromRGB(255, 150, 0)
            status = "KNOCKED"
        elseif humanoid.Health < humanoid.MaxHealth then
            color = Color3.fromRGB(255, 220, 50)
            status = "INJURED"
        else
            status = "IDLE"
        end
        
        if status == "IDLE" then
            statusText = string.format('<font color="#DDDDDD">%dm</font>', distance)
        else
            statusText = string.format('<font color="#DDDDDD">%dm</font> | <font color="#%s">%s</font>', 
                distance, color:ToHex(), status)
        end
    end
    
    -- OPTIMIZATION: Check if status changed (cache comparison)
    local userId = player.UserId
    local cachedData = PlayerESPData[userId]
    
    -- Calculate speed if enabled (ALWAYS calculate for accurate values)
    local speedText = ""
    local currentSpeed = 0
    if _G.ESP_ShowSpeed then
        currentSpeed = CalculatePlayerSpeed(player, root)
        if currentSpeed > 0 then
            speedText = string.format('\n<font color="#00FFFF">SPD: %d</font>', currentSpeed)
        end
    end
    
    -- Check if ESP enabled for this player type
    local showName = isKiller and _G.ESP_Killer_Name or _G.ESP_Survivor_Name
    
    if not showName then
        -- Remove billboard if disabled
        local billboard = root:FindFirstChild("TagESP")
        if billboard then billboard:Destroy() end
        PlayerESPData[userId] = nil
        return
    end
    
    -- Update cache (for reference only, don't block updates)
    PlayerESPData[userId] = {
        dist = distance,
        status = status,
        speed = currentSpeed
    }
    
    -- Create/Update Billboard
    local billboard = root:FindFirstChild("TagESP")
    
    if showName then
        if not billboard then
            -- Create new billboard
            billboard = Instance.new("BillboardGui")
            billboard.Name = "TagESP"
            billboard.Adornee = root
            billboard.Parent = root
            billboard.AlwaysOnTop = true
            billboard.Size = UDim2.new(0, 150, 0, 35)
            billboard.StudsOffset = Vector3.new(0, 4.5, 0)
            billboard.MaxDistance = 2000
            billboard.ResetOnSpawn = false
            
            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Parent = billboard
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 1, 0)
            label.Font = Enum.Font.GothamBold
            label.TextScaled = true
            label.RichText = true
            label.Text = string.format("<b>%s</b>\n%s%s", player.Name, statusText, speedText)
            label.TextColor3 = color
            label.TextYAlignment = Enum.TextYAlignment.Bottom
            
            local sizeConstraint = Instance.new("UITextSizeConstraint", label)
            sizeConstraint.MaxTextSize = 7
            sizeConstraint.MinTextSize = 5
            
            local stroke = Instance.new("UIStroke", label)
            stroke.Thickness = 1.5
            stroke.Color = Color3.fromRGB(10, 10, 10)
            stroke.Transparency = 0.3
            stroke.LineJoinMode = Enum.LineJoinMode.Round
        else
            -- Update existing billboard
            local label = billboard:FindFirstChild("Label")
            if label then
                local newText = string.format("<b>%s</b>\n%s%s", player.Name, statusText, speedText)
                if label.Text ~= newText then
                    label.Text = newText
                    label.TextColor3 = color
                end
            end
        end
    else
        -- Remove billboard if disabled
        if billboard then
            billboard:Destroy()
        end
    end
end

-- UPDATE GENERATOR ESP (From Melonz - Adapted)
local function UpdateGeneratorESP(generator)
    if not generator or not generator.Parent then
        return true
    end
    
    -- Get progress attribute (try multiple names)
    local progress = generator:GetAttribute("RepairProgress") 
                  or generator:GetAttribute("Progress")
                  or generator:GetAttribute("RepairPercent")
                  or 0
    
    local billboard = generator:FindFirstChild("GenBillboard")
    
    -- Remove if completed or disabled
    if progress >= 100 or not _G.ESP_Generator then
        if billboard then
            billboard:Destroy()
        end
        generator:SetAttribute("LastESPPercent", nil)
        return progress >= 100
    end
    
    -- Round to 1 decimal
    local percent = math.floor(progress * 10) / 10
    
    -- Update tracking attribute (for reference only, don't block updates)
    generator:SetAttribute("LastESPPercent", percent)
    
    -- Color lerp (orange → green)
    local clampedProgress = math.clamp(progress, 0, 100)
    local orangeStart = Color3.fromRGB(255, 140, 0)
    local greenEnd = Color3.fromRGB(0, 255, 120)
    local color = (clampedProgress < 50) 
        and orangeStart:Lerp(greenEnd, clampedProgress / 50)
        or orangeStart:Lerp(greenEnd, (clampedProgress - 50) / 50 + 0.5)
    
    -- Find part to attach billboard
    local targetPart = generator:FindFirstChild("defaultMaterial", true) 
                    or (generator:IsA("Model") and generator.PrimaryPart) 
                    or generator:FindFirstChildWhichIsA("BasePart", true)
    
    if not targetPart then
        return false
    end
    
    if not billboard then
        -- Create new billboard
        billboard = Instance.new("BillboardGui")
        billboard.Name = "GenBillboard"
        billboard.Parent = generator
        billboard.Adornee = targetPart
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.ResetOnSpawn = false
        billboard.MaxDistance = 260
        billboard.Size = UDim2.new(0, 140, 0, 28)
        billboard.StudsOffset = Vector3.new(0, 3.1, 0)
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Parent = billboard
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.TextScaled = false
        label.TextWrapped = false
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Font = Enum.Font.GothamBold
        label.TextSize = 8
        label.RichText = false
        label.Text = string.format("%.1f%%", percent)
        label.TextColor3 = color
        
        local stroke = Instance.new("UIStroke")
        stroke.Parent = label
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        stroke.Thickness = 1.1
        stroke.Transparency = 0.25
        stroke.Color = Color3.new(0, 0, 0)
        
        local sizeConstraint = Instance.new("UITextSizeConstraint")
        sizeConstraint.Parent = label
        sizeConstraint.MaxTextSize = 8
        sizeConstraint.MinTextSize = 6
    else
        -- ALWAYS update existing billboard text and color
        local label = billboard:FindFirstChild("Label")
        if label then
            label.Text = string.format("%.1f%%", percent)
            label.TextColor3 = color
        end
    end
    
    return false
end

-- MAIN ESP UPDATE LOOP (Optimized with rate limiting)
local function UpdateAllESP()
    -- OPTIMIZATION: Rate limiting (10 FPS for ESP updates)
    local currentTime = tick()
    if currentTime - LastESPUpdate < ESPUpdateRate then
        return
    end
    LastESPUpdate = currentTime
    
    -- Pre-validation
    if not Services.Workspace.CurrentCamera then return end
    if #Services.Players:GetPlayers() <= 1 then return end
    
    -- OPTIMIZATION: Get local player position once
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos = myRoot.Position
    
    -- ===== UPDATE PLAYERS (with distance culling) =====
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local team = player.Team
            local isKiller = false
            
            if team and team.Name then
                isKiller = string.find(string.lower(team.Name), "killer") ~= nil
            end
            
            local shouldShow = isKiller and _G.ESP_Killer_Name or _G.ESP_Survivor_Name
            
            if shouldShow or _G.ESP_ShowSpeed then
                -- OPTIMIZATION: Distance pre-check before full update
                local char = player.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local distance = (root.Position - myPos).Magnitude
                        
                        if distance <= ESPMaxDistance then
                            UpdatePlayerESP(player, isKiller)
                        else
                            -- OPTIMIZATION: Remove ESP if too far (saves render calls)
                            local billboard = root:FindFirstChild("TagESP")
                            if billboard then billboard:Destroy() end
                        end
                    end
                end
            else
                -- Remove ESP when disabled
                local char = player.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local billboard = root:FindFirstChild("TagESP")
                        if billboard then billboard:Destroy() end
                    end
                end
                PlayerPositions[player] = nil
            end
        end
    end
    
    -- ===== UPDATE GENERATORS (with caching) =====
    if _G.ESP_Generator then
        -- OPTIMIZATION: Re-scan generators every 2s instead of every frame
        if currentTime - LastGeneratorScan >= GeneratorScanRate then
            LastGeneratorScan = currentTime
            
            local map = Services.Workspace:FindFirstChild("Map")
            if map then
                CachedGenerators = {}
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj.Name == "Generator" and obj:IsA("Model") then
                        table.insert(CachedGenerators, obj)
                    end
                end
            end
        end
        
        -- Update only cached generators (filter out completed ones)
        local stillActive = {}
        for _, generator in ipairs(CachedGenerators) do
            if generator and generator.Parent then
                local isCompleted = UpdateGeneratorESP(generator)
                if not isCompleted then
                    table.insert(stillActive, generator)
                end
            end
        end
        CachedGenerators = stillActive
        
    else
        -- Cleanup all generator billboards when disabled
        if #CachedGenerators > 0 then
            for _, generator in ipairs(CachedGenerators) do
                if generator and generator.Parent then
                    local billboard = generator:FindFirstChild("GenBillboard")
                    if billboard then billboard:Destroy() end
                    generator:SetAttribute("LastESPPercent", nil)
                end
            end
            CachedGenerators = {}
        end
    end
end

-- START ESP
local function StartESP()
    if ESPConnection then return end
    
    -- OPTIMIZATION: Use Heartbeat instead of RenderStepped (more efficient for non-visual logic)
    ESPConnection = Services.RunService.Heartbeat:Connect(function()
        pcall(UpdateAllESP)
    end)
    
    print("[ESP] Started (Melonz System - Optimized)")
end

-- STOP ESP
local function StopESP()
    if ESPConnection then
        ESPConnection:Disconnect()
        ESPConnection = nil
    end
    
    -- Cleanup all player billboards
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local billboard = root:FindFirstChild("TagESP")
                if billboard then billboard:Destroy() end
            end
        end
    end
    
    -- Cleanup all generator billboards
    for _, generator in ipairs(CachedGenerators) do
        if generator and generator.Parent then
            local billboard = generator:FindFirstChild("GenBillboard")
            if billboard then billboard:Destroy() end
            generator:SetAttribute("LastESPPercent", nil)
        end
    end
    
    PlayerPositions = {}
    CachedGenerators = {}
    PlayerESPData = {}
    
    print("[ESP] Stopped")
end

-- AUTO-RESTART ESP when respawn/new match
local function SetupESPAutoRestart()
    -- Restart ESP when LocalPlayer respawns
    LocalPlayer.CharacterAdded:Connect(function(character)
        -- Wait for character to load
        character:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.5)
        
        -- Check if any ESP toggle is enabled
        if _G.ESP_Survivor_Name or _G.ESP_Killer_Name or _G.ESP_ShowSpeed or _G.ESP_Generator then
            print("[ESP] Auto-restarting after respawn...")
            
            -- Clean up first
            PlayerPositions = {}
            CachedGenerators = {}
            PlayerESPData = {}
            
            -- Restart ESP
            if not ESPConnection then
                StartESP()
            end
        end
    end)
    
    -- Monitor other players joining/leaving
    Services.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            -- Refresh ESP when new player spawns
            if ESPConnection then
                task.wait(0.5)
                LastESPUpdate = 0  -- Force immediate update
            end
        end)
    end)
    
    Services.Players.PlayerRemoving:Connect(function(player)
        -- Cleanup player data
        PlayerPositions[player] = nil
        PlayerESPData[player.UserId] = nil
    end)
end

-- Initialize auto-restart
SetupESPAutoRestart()

-- UI: ESP SECTION (Simple, no groups)
local ESPGroupBox = Tabs.Visuals:AddLeftGroupbox("ESP", "eye")

ESPGroupBox:AddToggle("ESP_Survivor_Name", {
    Text = "ESP Survivor",
    Default = false,
    Callback = function(Value)
        _G.ESP_Survivor_Name = Value
        if Value then StartESP() else UpdateAllESP() end
    end
})

ESPGroupBox:AddToggle("ESP_Killer_Name", {
    Text = "ESP Killer",
    Default = false,
    Callback = function(Value)
        _G.ESP_Killer_Name = Value
        if Value then StartESP() else UpdateAllESP() end
    end
})

ESPGroupBox:AddDivider()

ESPGroupBox:AddToggle("ESP_ShowSpeed", {
    Text = "Show Speed",
    Default = false,
    Callback = function(Value)
        _G.ESP_ShowSpeed = Value
        if Value then StartESP() else UpdateAllESP() end
    end
})

ESPGroupBox:AddDivider()

ESPGroupBox:AddToggle("ESP_Generator", {
    Text = "Generator Progress %",
    Default = false,
    Callback = function(Value)
        _G.ESP_Generator = Value
        if Value then StartESP() else UpdateAllESP() end
    end
})

ESPGroupBox:AddToggle("ESP_Pallet", {
    Text = "ESP Pallet",
    Default = false,
    Callback = function(Value)
        _G.ESP_Pallet = Value
    end
})

ESPGroupBox:AddToggle("ESP_Gate", {
    Text = "ESP Exit Gate",
    Default = false,
    Callback = function(Value)
        _G.ESP_Gate = Value
    end
})

ESPGroupBox:AddToggle("ESP_Hook", {
    Text = "ESP Hook",
    Default = false,
    Callback = function(Value)
        _G.ESP_Hook = Value
    end
})

ESPGroupBox:AddDivider()
ESPGroupBox:AddLabel("Features:")
ESPGroupBox:AddLabel("  • Status: HOOKED, CARRIED, KNOCKED, INJURED")
ESPGroupBox:AddLabel("  • Killer Type: 7 killers auto-detect")
ESPGroupBox:AddLabel("  • Speed: Real-time walkspeed (SPD)")

ESPGroupBox:AddDivider()
ESPGroupBox:AddLabel("Performance:")

ESPGroupBox:AddSlider("ESPUpdateRate", {
    Text = "Update Rate",
    Default = 0.1,
    Min = 0.05,
    Max = 0.5,
    Rounding = 2,
    Compact = false,
    Callback = function(Value)
        ESPUpdateRate = Value
        print("[ESP] Update rate:", Value, "seconds")
    end
})

ESPGroupBox:AddSlider("ESPMaxDistance", {
    Text = "Max Distance",
    Default = 500,
    Min = 100,
    Max = 1000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        ESPMaxDistance = Value
        print("[ESP] Max distance:", Value, "studs")
    end
})

print("[ESP] Melonz system loaded (Billboard + Status + Speed + Optimized)")

-- ========================================
-- CHAMS SYSTEM (KEEP EXISTING)
-- ========================================

local ChamsGroupBox = Tabs.Visuals:AddLeftGroupbox("Chams", "eye")

-- OPTIMIZED CHAMS SYSTEM (Based on open source - No lag!)
_G.ESP = { 
    Killer = false, 
    Survivor = false, 
    Generator = false, 
    Pallet = false, 
    Window = false,
    Gate = false,
    Hook = false
}
_G.ChamsColors = {
    Killer = Color3.fromRGB(255, 0, 0),
    Survivor = Color3.fromRGB(0, 255, 0),
    Generator = Color3.fromRGB(255, 165, 0),
    Pallet = Color3.fromRGB(255, 100, 100),
    Window = Color3.fromRGB(100, 200, 255),
    Gate = Color3.fromRGB(255, 255, 255),
    Hook = Color3.fromRGB(132, 255, 169)
}
_G.ChamsMode = "Full" -- Full or Outline

local Highlights = {}
local ActiveGenerators = {}
local TrackedObjects = {}
local LastFullESPRefresh = 0
local LastChamsUpdate = 0  -- OPTIMIZATION: Rate limiting for chams
local ChamsUpdateRate = 0.1  -- Update chams every 0.1s (10 FPS)
local ChamsMaxDistance = 800  -- Only show chams within 800 studs

-- ========================================
-- GRAPHICS & FOV (Right Side - Below ESP Info)
-- ========================================

-- Apply highlight without recreating (optimized + enhanced visual!)
local function ApplyHighlight(object, color)
    if not object or not object.Parent then return end
    
    -- OPTIMIZATION: Check if highlight already exists with correct properties
    local h = Highlights[object] or object:FindFirstChild("WolfESP")
    
    if not h then
        -- Create new highlight
        local success = pcall(function()
            h = Instance.new("Highlight")
            h.Name = "WolfESP"
            h.Adornee = object
            h.Parent = object
            Highlights[object] = h
        end)
        
        if not success then return end
    else
        -- OPTIMIZATION: If color hasn't changed, skip update
        if h.FillColor == color and h.Enabled then
            return
        end
    end
    
    if h then
        -- Update properties with ENHANCED VISUALS
        pcall(function()
            h.FillColor = color
            
            -- Outline color slightly brighter for better visibility
            local r, g, b = color.R, color.G, color.B
            h.OutlineColor = Color3.fromRGB(
                math.min(255, r * 255 + 50),
                math.min(255, g * 255 + 50),
                math.min(255, b * 255 + 50)
            )
            
            if _G.ChamsMode == "Outline" then
                -- Outline only mode - completely transparent fill
                h.FillTransparency = 1
                h.OutlineTransparency = 0
            else -- Full mode
                -- Semi-transparent fill for better visibility
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
            end
            
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Enabled = true
        end)
    end
end

-- Remove highlight
local function RemoveHighlight(obj)
    if not obj then return end
    
    pcall(function()
        local h = obj:FindFirstChild("WolfESP")
        if h then h:Destroy() end
    end)
    
    Highlights[obj] = nil
    TrackedObjects[obj] = nil
end

-- Update single player chams (called frequently)
local function UpdatePlayerChams(player)
    if not player or player == LocalPlayer or not player.Character then
        if Highlights[player] then
            RemoveHighlight(player.Character)
        end
        return
    end
    
    local teamName = player.Team and player.Team.Name or ""
    
    if teamName == "Killer" and _G.ESP.Killer then
        ApplyHighlight(player.Character, _G.ChamsColors.Killer)
        TrackedObjects[player.Character] = "Killer"
    elseif teamName == "Survivors" and _G.ESP.Survivor then
        ApplyHighlight(player.Character, _G.ChamsColors.Survivor)
        TrackedObjects[player.Character] = "Survivor"
    else
        if TrackedObjects[player.Character] then
            RemoveHighlight(player.Character)
        end
    end
end

-- Full ESP refresh (called every 5 seconds only!)
local function RefreshESP()
    ActiveGenerators = {}
    TrackedObjects = {}
    
    local Map = Services.Workspace:FindFirstChild("Map")
    if not Map then return end
    
    -- OPTIMIZATION: Batch processing in pcall to avoid repeated error checking
    local objectsProcessed = 0
    
    pcall(function()
        -- OPTIMIZATION: Use GetDescendants once and filter
        local descendants = Map:GetDescendants()
        
        for i = 1, #descendants do
            local obj = descendants[i]
            
            -- Only process Models
            if obj:IsA("Model") then
                local objName = obj.Name
                
                -- Single if-elseif chain
                if objName == "Generator" and _G.ESP.Generator then
                    ApplyHighlight(obj, _G.ChamsColors.Generator)
                    table.insert(ActiveGenerators, obj)
                    TrackedObjects[obj] = "Generator"
                    objectsProcessed = objectsProcessed + 1
                    
                elseif (objName == "Pallet" or objName == "Palletwrong") and _G.ESP.Pallet then
                ApplyHighlight(obj, _G.ChamsColors.Pallet)
                TrackedObjects[obj] = "Pallet"
                objectsProcessed = objectsProcessed + 1
                
            elseif objName == "Window" and _G.ESP.Window then
                ApplyHighlight(obj, _G.ChamsColors.Window)
                TrackedObjects[obj] = "Window"
                objectsProcessed = objectsProcessed + 1
                
            elseif objName == "Gate" and _G.ESP.Gate then
                ApplyHighlight(obj, _G.ChamsColors.Gate)
                TrackedObjects[obj] = "Gate"
                objectsProcessed = objectsProcessed + 1
                
            elseif objName == "Hook" and _G.ESP.Hook then
                -- Hook has Model inside with MeshParts
                local model = obj:FindFirstChild("Model")
                if model then
                    local parts = model:GetDescendants()
                    for j = 1, #parts do
                        local part = parts[j]
                        if part:IsA("MeshPart") then
                            ApplyHighlight(part, _G.ChamsColors.Hook)
                            TrackedObjects[part] = "Hook"
                            objectsProcessed = objectsProcessed + 1
                        end
                    end
                end
            end
            end  -- Close if obj:IsA("Model")
        end
    end)
    
    DevLog(string.format("Chams refresh: %d objects processed", objectsProcessed), "CHAMS")
end

-- Clear specific type of ESP
local function ClearESPType(espType)
    local removed = 0
    
    for obj, objType in pairs(TrackedObjects) do
        if objType == espType then
            RemoveHighlight(obj)
            removed = removed + 1
        end
    end
    
    DevLog(string.format("Cleared %d %s highlights", removed, espType), "CHAMS")
end

-- Clear all highlights
local function ClearAllESP()
    local count = 0
    
    for obj in pairs(Highlights) do
        RemoveHighlight(obj)
        count = count + 1
    end
    
    Highlights = {}
    TrackedObjects = {}
    ActiveGenerators = {}
    
    DevLog(string.format("Cleared all ESP - %d highlights removed", count), "CHAMS")
end

-- Start ESP system (OPTIMIZED with rate limiting)
local function startESP()
    -- Force stop if already running (allow restart)
    if ESPConnection then
        ESPConnection:Disconnect()
        ESPConnection = nil
        task.wait(0.1)  -- Small delay for cleanup
    end
    
    -- Reset timing variables
    LastChamsUpdate = 0
    LastFullESPRefresh = 0
    
    ESPConnection = Services.RunService.Heartbeat:Connect(function()
        -- OPTIMIZATION: Rate limiting for Chams
        local currentTime = tick()
        if currentTime - LastChamsUpdate < ChamsUpdateRate then
            return
        end
        LastChamsUpdate = currentTime
        
        -- Full refresh every 5 seconds (for map objects)
        if currentTime - LastFullESPRefresh > 5 then
            LastFullESPRefresh = currentTime
            RefreshESP()
        end
        
        -- OPTIMIZATION: Distance culling for player chams
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        for _, player in pairs(Services.Players:GetPlayers()) do
            if player ~= LocalPlayer then
                pcall(function()
                    -- Distance check
                    if myRoot and player.Character then
                        local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        if theirRoot then
                            local distance = (theirRoot.Position - myRoot.Position).Magnitude
                            
                            if distance <= ChamsMaxDistance then
                                UpdatePlayerChams(player)
                            else
                                -- Remove chams if too far
                                if TrackedObjects[player.Character] then
                                    RemoveHighlight(player.Character)
                                end
                            end
                        else
                            UpdatePlayerChams(player)
                        end
                    else
                        UpdatePlayerChams(player)
                    end
                end)
            end
        end
    end)
    
    -- Initial refresh (CRITICAL for immediate visibility)
    task.spawn(function()
        task.wait(0.2)  -- Slightly longer delay for workspace to be ready
        RefreshESP()
        DevLog("Initial Chams refresh completed", "CHAMS")
    end)
    
    DevLog("Optimized Chams system started (10 FPS update, 800 studs max)", "CHAMS")
    print("[Chams] Started (Optimized)")
end

-- Stop ESP system
local function stopESP()
    if ESPConnection then
        ESPConnection:Disconnect()
        ESPConnection = nil
    end
    
    ClearAllESP()
    
    DevLog("Chams system stopped", "CHAMS")
    print("[Chams] Stopped")
end

-- AUTO-RESTART CHAMS when respawn/new match
LocalPlayer.CharacterAdded:Connect(function(character)
    -- Wait for character to load
    character:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.5)
    
    -- Check if any Chams toggle is enabled
    local anyChamEnabled = _G.ESP.Killer or _G.ESP.Survivor or _G.ESP.Generator 
                        or _G.ESP.Pallet or _G.ESP.Window or _G.ESP.Gate or _G.ESP.Hook
    
    if anyChamEnabled and not ESPConnection then
        print("[Chams] Auto-restarting after respawn...")
        startESP()
    end
end)

-- Event: New map loaded
Services.Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        task.wait(1)
        if ESPConnection then
            RefreshESP()
            print("[Chams] Map detected - ESP refreshed")
        end
    end
end)

-- Event: Player removing
Services.Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        RemoveHighlight(player.Character)
    end
    -- Clear position tracking
    PlayerPositions[player] = nil
end)

-- Chams Mode Selection
ChamsGroupBox:AddDropdown("ChamsMode", {
    Values = {"Full", "Outline"},
    Default = 1,
    Multi = false,
    Text = "Chams Mode",
    Tooltip = "Full: See through walls | Outline: Only borders",
    Callback = function(Value)
        _G.ChamsMode = Value
        
        -- Update all existing highlights with new mode
        if ESPConnection then
            RefreshESP()
        end
        
        print("[Chams] Mode:", Value)
    end
})

ChamsGroupBox:AddDivider()

ChamsGroupBox:AddToggle("KillerChams", {
    Text = "Killer",
    Default = false,
    Tooltip = "Highlight killers",
    Callback = function(Value)
        _G.ESP.Killer = Value
        if Value then 
            startESP() 
        else
            ClearESPType("Killer")
            
            -- Stop ESP if nothing else enabled
            if not _G.ESP.Survivor and not _G.ESP.Generator and not _G.ESP.Pallet and not _G.ESP.Window then 
                stopESP() 
            end
        end
    end
}):AddColorPicker("KillerColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Killer Color",
    Callback = function(Value)
        _G.ChamsColors.Killer = Value
        if _G.ESP.Killer and ESPConnection then
            RefreshESP()
        end
        print("[Chams] Killer color:", Value)
    end
})

ChamsGroupBox:AddToggle("SurvivorChams", {
    Text = "Survivor",
    Default = false,
    Tooltip = "Highlight survivors",
    Callback = function(Value)
        _G.ESP.Survivor = Value
        if Value then 
            startESP() 
        else
            ClearESPType("Survivor")
            
            if not _G.ESP.Killer and not _G.ESP.Generator and not _G.ESP.Pallet and not _G.ESP.Window then 
                stopESP() 
            end
        end
    end
}):AddColorPicker("SurvivorColor", {
    Default = Color3.fromRGB(0, 255, 0),
    Title = "Survivor Color",
    Callback = function(Value)
        _G.ChamsColors.Survivor = Value
        if _G.ESP.Survivor and ESPConnection then
            RefreshESP()
        end
        print("[Chams] Survivor color:", Value)
    end
})

ChamsGroupBox:AddToggle("GeneratorChams", {
    Text = "Generator",
    Default = false,
    Tooltip = "Highlight generators",
    Callback = function(Value)
        _G.ESP.Generator = Value
        if Value then 
            startESP() 
        else
            ClearESPType("Generator")
            
            if not _G.ESP.Killer and not _G.ESP.Survivor and not _G.ESP.Pallet and not _G.ESP.Window then 
                stopESP() 
            end
        end
    end
}):AddColorPicker("GeneratorColor", {
    Default = Color3.fromRGB(255, 165, 0),
    Title = "Generator Color",
    Callback = function(Value)
        _G.ChamsColors.Generator = Value
        if _G.ESP.Generator and ESPConnection then 
            RefreshESP() 
        end
        print("[Chams] Generator color:", Value)
    end
})

ChamsGroupBox:AddToggle("PalletChams", {
    Text = "Pallet",
    Default = false,
    Tooltip = "Highlight pallets",
    Callback = function(Value)
        _G.ESP.Pallet = Value
        if Value then 
            startESP() 
        else
            ClearESPType("Pallet")
            
            if not _G.ESP.Killer and not _G.ESP.Survivor and not _G.ESP.Generator and not _G.ESP.Window then 
                stopESP() 
            end
        end
    end
}):AddColorPicker("PalletColor", {
    Default = Color3.fromRGB(255, 100, 100),
    Title = "Pallet Color",
    Callback = function(Value)
        _G.ChamsColors.Pallet = Value
        if _G.ESP.Pallet and ESPConnection then 
            RefreshESP() 
        end
        print("[Chams] Pallet color:", Value)
    end
})

ChamsGroupBox:AddToggle("WindowChams", {
    Text = "Window",
    Default = false,
    Tooltip = "Highlight windows",
    Callback = function(Value)
        _G.ESP.Window = Value
        if Value then 
            startESP() 
        else
            ClearESPType("Window")
            
            if not _G.ESP.Killer and not _G.ESP.Survivor and not _G.ESP.Generator and not _G.ESP.Pallet and not _G.ESP.Gate and not _G.ESP.Hook then 
                stopESP() 
            end
        end
    end
}):AddColorPicker("WindowColor", {
    Default = Color3.fromRGB(100, 200, 255),
    Title = "Window Color",
    Callback = function(Value)
        _G.ChamsColors.Window = Value
        if _G.ESP.Window and ESPConnection then 
            RefreshESP() 
        end
        print("[Chams] Window color:", Value)
    end
})

ChamsGroupBox:AddToggle("GateChams", {
    Text = "Gate",
    Default = false,
    Tooltip = "Highlight exit gates",
    Callback = function(Value)
        _G.ESP.Gate = Value
        if Value then 
            startESP() 
        else
            ClearESPType("Gate")
            
            if not _G.ESP.Killer and not _G.ESP.Survivor and not _G.ESP.Generator and not _G.ESP.Pallet and not _G.ESP.Window and not _G.ESP.Hook then 
                stopESP() 
            end
        end
    end
}):AddColorPicker("GateColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Gate Color",
    Callback = function(Value)
        _G.ChamsColors.Gate = Value
        if _G.ESP.Gate and ESPConnection then 
            RefreshESP() 
        end
        print("[Chams] Gate color:", Value)
    end
})

ChamsGroupBox:AddToggle("HookChams", {
    Text = "Hook",
    Default = false,
    Tooltip = "Highlight hooks",
    Callback = function(Value)
        _G.ESP.Hook = Value
        if Value then 
            startESP() 
        else
            ClearESPType("Hook")
            
            if not _G.ESP.Killer and not _G.ESP.Survivor and not _G.ESP.Generator and not _G.ESP.Pallet and not _G.ESP.Window and not _G.ESP.Gate then 
                stopESP() 
            end
        end
    end
}):AddColorPicker("HookColor", {
    Default = Color3.fromRGB(132, 255, 169),
    Title = "Hook Color",
    Callback = function(Value)
        _G.ChamsColors.Hook = Value
        if _G.ESP.Hook and ESPConnection then 
            RefreshESP() 
        end
        print("[Chams] Hook color:", Value)
    end
})

ChamsGroupBox:AddDivider()
ChamsGroupBox:AddLabel("Performance Settings")

ChamsGroupBox:AddSlider("ChamsUpdateRate", {
    Text = "Update Rate",
    Default = 0.1,
    Min = 0.05,
    Max = 0.5,
    Rounding = 2,
    Compact = false,
    Callback = function(Value)
        ChamsUpdateRate = Value
        print("[Chams] Update rate:", Value, "seconds (higher = better FPS)")
    end
})

ChamsGroupBox:AddSlider("ChamsMaxDistance", {
    Text = "Max Distance",
    Default = 800,
    Min = 200,
    Max = 2000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        ChamsMaxDistance = Value
        print("[Chams] Max distance:", Value, "studs")
    end
})

-- ========================================
-- GRAPHICS & FOV (Right Side)
-- ========================================


local GraphicsGroupBox = Tabs.Visuals:AddRightGroupbox("Graphics & FOV", "monitor")

-- No Shadow & Full Bright (FIXED IMPLEMENTATION dengan Loop)
_G.NoShadowEnabled = false
_G.FullBrightEnabled = false
local LightingLoop = nil

local function startLightingLoop()
    if LightingLoop then return end
    
    LightingLoop = Services.RunService.Heartbeat:Connect(function()
        pcall(function()
            if _G.FullBrightEnabled then
                Services.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Services.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Services.Lighting.Brightness = 2
                Services.Lighting.ClockTime = 14
                Services.Lighting.GlobalShadows = false
                Services.Lighting.FogEnd = 9e9
            elseif _G.NoShadowEnabled then
                Services.Lighting.GlobalShadows = false
                Services.Lighting.FogEnd = 9e9
            end
        end)
    end)
    print("[Lighting Loop] Started")
end

local function stopLightingLoop()
    if LightingLoop then
        LightingLoop:Disconnect()
        LightingLoop = nil
    end
    
    pcall(function()
        Services.Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Services.Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
        Services.Lighting.Brightness = 1
        Services.Lighting.ClockTime = 0
        Services.Lighting.GlobalShadows = true
        Services.Lighting.FogEnd = 100000
    end)
    print("[Lighting Loop] Stopped")
end

GraphicsGroupBox:AddToggle("NoShadow", {
    Text = "No Shadow",
    Default = false,
    Tooltip = "Disable all shadows for better visibility",
    Callback = function(Value)
        _G.NoShadowEnabled = Value
        
        if Value then
            startLightingLoop()
            print("[No Shadow] On")
        else
            if not _G.FullBrightEnabled then
                stopLightingLoop()
            end
            print("[No Shadow] Off")
        end
    end
})

GraphicsGroupBox:AddToggle("FullBright", {
    Text = "Full Bright",
    Default = false,
    Tooltip = "Maximum brightness everywhere",
    Callback = function(Value)
        _G.FullBrightEnabled = Value
        
        if Value then
            startLightingLoop()
            print("[Full Bright] On")
        else
            if not _G.NoShadowEnabled then
                stopLightingLoop()
            end
            print("[Full Bright] Off")
        end
    end
})

-- Remove Post Processing
_G.RemovePostProcessingEnabled = false

GraphicsGroupBox:AddToggle("RemovePostProcessing", {
    Text = "Remove Post Processing",
    Default = false,
    Tooltip = "Remove bloom, blur, color correction, etc.",
    Callback = function(Value)
        _G.RemovePostProcessingEnabled = Value
        
        pcall(function()
            for _, effect in pairs(Services.Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or 
                   effect:IsA("BloomEffect") or 
                   effect:IsA("BlurEffect") or 
                   effect:IsA("ColorCorrectionEffect") or 
                   effect:IsA("SunRaysEffect") or 
                   effect:IsA("DepthOfFieldEffect") then
                    effect.Enabled = not Value
                end
            end
            
            -- Also check Cameras
            for _, camera in pairs(Services.Workspace:GetDescendants()) do
                if camera:IsA("Camera") then
                    for _, effect in pairs(camera:GetChildren()) do
                        if effect:IsA("PostEffect") or 
                           effect:IsA("BloomEffect") or 
                           effect:IsA("BlurEffect") or 
                           effect:IsA("ColorCorrectionEffect") or 
                           effect:IsA("SunRaysEffect") or 
                           effect:IsA("DepthOfFieldEffect") then
                            effect.Enabled = not Value
                        end
                    end
                end
            end
        end)
        
        print("[Remove Post Processing]", Value and "On" or "Off")
    end
})

-- Remove Fog
_G.RemoveFogEnabled = false
local OriginalFogSettings = {
    FogEnd = 100000,
    FogStart = 0,
    FogColor = Color3.new(0.75, 0.75, 0.75)
}

GraphicsGroupBox:AddToggle("RemoveFog", {
    Text = "Remove Fog",
    Default = false,
    Tooltip = "Remove all fog for better visibility",
    Callback = function(Value)
        _G.RemoveFogEnabled = Value
        
        pcall(function()
            if Value then
                -- Save original settings
                OriginalFogSettings.FogEnd = Services.Lighting.FogEnd
                OriginalFogSettings.FogStart = Services.Lighting.FogStart
                OriginalFogSettings.FogColor = Services.Lighting.FogColor
                
                -- Remove fog
                Services.Lighting.FogEnd = 9e9
                Services.Lighting.FogStart = 0
                
                print("[Remove Fog] On")
            else
                -- Restore original settings
                Services.Lighting.FogEnd = OriginalFogSettings.FogEnd
                Services.Lighting.FogStart = OriginalFogSettings.FogStart
                Services.Lighting.FogColor = OriginalFogSettings.FogColor
                
                print("[Remove Fog] Off")
            end
        end)
    end
})

GraphicsGroupBox:AddDivider()

-- Low Graphics System
_G.LowGraphicsEnabled = false
local OriginalMaterials = {}
local OriginalTransparencies = {}
local OriginalEffects = {}

local function applyLowGraphics()
    _G.LowGraphicsEnabled = true
    
    task.spawn(function()
        -- Apply to all existing objects
        for _, obj in pairs(Services.Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                OriginalMaterials[obj] = obj.Material
                obj.Material = Enum.Material.Plastic
            elseif (obj:IsA("Texture") or obj:IsA("Decal")) and obj.Name ~= "face" then
                OriginalTransparencies[obj] = obj.Transparency
                obj.Transparency = 1
            elseif obj:IsA("SurfaceGui") then
                OriginalTransparencies[obj] = obj.Transparency or 0
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                OriginalEffects[obj] = obj.Enabled
                obj.Enabled = false
            end
        end
        
        print("[Low Graphics] Enabled")
    end)
end

local function disableLowGraphics()
    _G.LowGraphicsEnabled = false
    
    task.spawn(function()
        -- Restore original materials
        for obj, material in pairs(OriginalMaterials) do
            if obj.Parent then
                obj.Material = material
            end
        end
        
        -- Restore original transparencies
        for obj, transparency in pairs(OriginalTransparencies) do
            if obj.Parent then
                obj.Transparency = transparency
            end
        end
        
        -- Restore original effects
        for obj, enabled in pairs(OriginalEffects) do
            if obj.Parent then
                obj.Enabled = enabled
            end
        end
        
        -- Clear tables
        OriginalMaterials = {}
        OriginalTransparencies = {}
        OriginalEffects = {}
        
        print("[Low Graphics] Disabled")
    end)
end

-- Auto-apply low graphics to new objects
Services.Workspace.DescendantAdded:Connect(function(obj)
    if not _G.LowGraphicsEnabled then return end
    
    task.spawn(function()
        if obj:IsA("BasePart") then
            OriginalMaterials[obj] = obj.Material
            obj.Material = Enum.Material.Plastic
        elseif (obj:IsA("Texture") or obj:IsA("Decal")) and obj.Name ~= "face" then
            OriginalTransparencies[obj] = obj.Transparency
            obj.Transparency = 1
        elseif obj:IsA("SurfaceGui") then
            OriginalTransparencies[obj] = obj.Transparency or 0
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            OriginalEffects[obj] = obj.Enabled
            obj.Enabled = false
        end
    end)
end)

GraphicsGroupBox:AddToggle("LowGraphics", {
    Text = "Low Graphics",
    Default = false,
    Tooltip = "Reduce graphics quality for better performance",
    Callback = function(Value)
        if Value then
            applyLowGraphics()
        else
            disableLowGraphics()
        end
    end
})

-- ========================================
-- SETTINGS TAB
-- ========================================

local UIControlsGroupBox = Tabs.Settings:AddLeftGroupbox("UI Controls", "settings")

UIControlsGroupBox:AddLabel("Toggle UI: RightShift")
UIControlsGroupBox:AddDivider()

-- Status Label Toggle
UIControlsGroupBox:AddToggle("ShowStatusLabel", {
    Text = "Show Status Label",
    Default = true,
    Tooltip = "Show/hide draggable status label (WolfFamily, FPS, Ping)",
    Callback = function(Value)
        DraggableLabel:SetVisible(Value)
        print("[Status Label]", Value and "Shown" or "Hidden")
    end
})

UIControlsGroupBox:AddDivider()

UIControlsGroupBox:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Show Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end
})

UIControlsGroupBox:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(value)
        Library.ShowCustomCursor = value
    end
})

UIControlsGroupBox:AddButton({
    Text = "Unload Script",
    Func = function()
        if ESPConnection then stopESP() end
        if AimbotConnection then AimbotConnection:Disconnect() end
        if _G.AutoAttackConn then _G.AutoAttackConn:Disconnect() end
        if LightingLoop then stopLightingLoop() end
        if HeartbeatConnection then HeartbeatConnection:Disconnect() end
        if ParryConnection then ParryConnection:Disconnect() end
        if CameraConnection then CameraConnection:Disconnect() end
        RemoveRangeCircle()
        if DraggableLabel then DraggableLabel:SetVisible(false) end
        Library:Unload()
        print("[WolfHub] Unloaded")
    end,
    Tooltip = "Completely remove the script"
})

-- ========================================
-- CONFIGURATION & THEME SECTION
-- ========================================

-- Setup SaveManager and ThemeManager
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('WolfFamilyHub')
SaveManager:SetFolder('WolfFamilyHub/violence-district')

-- Build Configuration section (auto-generates groupbox with save/load buttons)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Apply Theme Manager to Settings tab (adds theme controls)
ThemeManager:ApplyToTab(Tabs.Settings)

-- Add Menu Controls groupbox (custom)
local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu Controls', "settings")
MenuGroup:AddLabel('Menu keybind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' })
MenuGroup:AddButton('Unload Script', function() Library:Unload() end)

-- Auto-load configuration
task.spawn(function()
    task.wait(1)
    SaveManager:LoadAutoloadConfig()
end)

-- Menu keybind handler
Library.ToggleKeybind = Options.MenuKeybind

-- Initialize Mobile Shortcuts
task.spawn(function()
    task.wait(1)
    InitializeShortcuts()
    print("[Mobile Shortcuts] Initialized - 5 draggable buttons ready")
end)

print("[WolfHub] Loaded successfully!")
print("[WolfHub] Version: V0.1.0-Fix-28_Early")
print("[WolfHub] NEW: Silent Aim (Twist of Fate Gun)")
print("[WolfHub] Features:")
print("  - Silent Aim: Auto-aim gun to Killer (shortcut button)")
print("  - Speed Boost: 0-100% extra speed with normal animation")
print("  - Mobile Shortcuts: 6 floating buttons (configurable)")
print("  - Invisible Attack: Counter auto-parry")
print("  - General: Camera Unlock + FOV Changer")
print("  - Auto Parry: SixSense (4 features)")
print("  - ESP Info + Chams/ESP + Graphics + More")

DevLog("WolfHub fully loaded - V0.1.0-Fix-28_Early", "SYSTEM")
DevLog("Silent Aim: Twist of Fate gun auto-aim", "FEATURE")
DevLog("All features use _G (no getgenv)", "TECH")
DevLog("Speed Boost with locked animation", "FEATURE")
DevLog("Mobile Shortcuts with error handling", "FEATURE")
DevLog("ESP Info: Manual toggle (default OFF)", "FEATURE")


-- ========================================
-- ANTI-LOGGER SYSTEM (BYPASS ANTI-CHEAT)
-- ========================================

_G.AntiLoggerEnabled = true
local AntiLoggerHooked = false

local function SetupAntiLogger()
    if AntiLoggerHooked then return end
    
    task.spawn(function()
        local success = pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                
                if _G.AntiLoggerEnabled and method == "FireServer" then
                    local remoteName = self.Name:lower()
                    
                    -- Block suspicious remotes
                    local blockedTerms = {"log", "error", "report", "anticheat", "ban", "kick", "flag"}
                    
                    for _, term in ipairs(blockedTerms) do
                        if remoteName:find(term) then
                            DevLog(string.format("Blocked remote: %s", self.Name), "ANTI-LOGGER")
                            return nil  -- Block the call
                        end
                    end
                end
                
                return oldNamecall(self, ...)
            end)
            
            AntiLoggerHooked = true
            print("[Anti-Logger] ✅ Hooked successfully - Blocking suspicious remotes")
        end)
        
        if not success then
            warn("[Anti-Logger] ⚠️ Failed to hook")
        end
    end)
end

-- Initialize immediately
SetupAntiLogger()

-- ========================================
-- ANTI-AURA SYSTEM
-- ========================================

_G.AntiAuraEnabled = false
local AntiAuraHooked = false

local function SetupAntiAura()
    if AntiAuraHooked then return end
    
    task.spawn(function()
        local success = pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if _G.AntiAuraEnabled and method == "FireServer" then
                    local remoteName = self.Name:lower()
                    
                    -- Block aura/reveal remotes
                    local blockedTerms = {"aura", "reveal", "highlight", "sense", "spotted", "vision", "radar", "detect", "tracking", "hunter"}
                    
                    for _, term in ipairs(blockedTerms) do
                        if remoteName:find(term) then
                            -- Check if player is in arguments
                            for _, arg in ipairs(args) do
                                if arg == LocalPlayer or arg == LocalPlayer.Character then
                                    DevLog(string.format("Blocked aura remote: %s", self.Name), "ANTI-AURA")
                                    return nil  -- Block the call
                                end
                            end
                        end
                    end
                end
                
                return oldNamecall(self, ...)
            end)
            
            AntiAuraHooked = true
            print("[Anti-Aura] ✅ Hooked successfully")
        end)
        
        if not success then
            warn("[Anti-Aura] ⚠️ Failed to hook")
        end
    end)
end

-- ========================================
-- POTATO MODE (FPS BOOST)
-- ========================================

_G.PotatoModeEnabled = false
local OriginalSettings = {}

local function EnablePotatoMode()
    print("[Potato Mode] Enabling...")
    
    -- Save original lighting settings
    OriginalSettings.Lighting = {
        Brightness = Services.Lighting.Brightness,
        Technology = Services.Lighting.Technology,
        GlobalShadows = Services.Lighting.GlobalShadows,
        OutdoorAmbient = Services.Lighting.OutdoorAmbient
    }
    
    -- Optimize lighting
    Services.Lighting.Brightness = 2
    Services.Lighting.GlobalShadows = false
    Services.Lighting.Technology = Enum.Technology.Compatibility
    
    -- Remove post effects
    for _, effect in pairs(Services.Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Atmosphere") then
            effect.Enabled = false
        end
    end
    
    -- Optimize workspace parts
    for _, obj in pairs(Services.Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("BasePart") then
                -- Remove textures and optimize material
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
                
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
                
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Enabled = false
                
            elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end)
    end
    
    -- Optimize terrain
    local terrain = Services.Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
    end
    
    print("[Potato Mode] ✅ Enabled - FPS optimized!")
end

local function DisablePotatoMode()
    print("[Potato Mode] Disabling...")
    
    -- Restore lighting
    if OriginalSettings.Lighting then
        Services.Lighting.Brightness = OriginalSettings.Lighting.Brightness
        Services.Lighting.Technology = OriginalSettings.Lighting.Technology
        Services.Lighting.GlobalShadows = OriginalSettings.Lighting.GlobalShadows
        Services.Lighting.OutdoorAmbient = OriginalSettings.Lighting.OutdoorAmbient
    end
    
    -- Restore post effects
    for _, effect in pairs(Services.Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Atmosphere") then
            effect.Enabled = true
        end
    end
    
    print("[Potato Mode] ✅ Disabled - Settings restored!")
end


-- ========================================
-- SMART AI AUTO PLAY (AI BOT)
-- ========================================

_G.AIEnabled = false
_G.AISpeed = 17
_G.AIState = "Idle"

local PathfindingService = game:GetService("PathfindingService")
local AIConnection = nil
local CurrentPath = nil
local CurrentWaypoint = 1

-- AI States
local AIStates = {
    Evading = "Evading",    -- Run from killer
    Repairing = "Repairing", -- Repair generator
    Healing = "Healing",     -- Heal teammate
    Escaping = "Escaping",   -- Go to exit gate
    Idle = "Idle"            -- Waiting/deciding
}

-- Find nearest killer
local function FindNearestKiller()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
    
    local myPos = myChar.HumanoidRootPart.Position
    local nearestKiller = nil
    local minDist = math.huge
    
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team.Name == "Killer" then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearestKiller = player
                end
            end
        end
    end
    
    return nearestKiller, minDist
end

-- Find nearest incomplete generator
local function FindNearestGenerator()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myPos = myChar.HumanoidRootPart.Position
    local nearest = nil
    local minDist = math.huge
    
    for _, obj in pairs(Services.Workspace:GetDescendants()) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            local progress = obj:GetAttribute("RepairProgress") or 0
            
            if progress < 100 then
                local dist = (obj:GetPivot().Position - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    
    return nearest
end

-- Find injured teammate
local function FindInjuredTeammate()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team == LocalPlayer.Team then
            if player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health < humanoid.MaxHealth * 0.5 then
                    return player
                end
            end
        end
    end
    
    return nil
end

-- Create path to target
local function CreatePathTo(targetPos)
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return false end
    
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    })
    
    local success, err = pcall(function()
        path:ComputeAsync(myChar.HumanoidRootPart.Position, targetPos)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        CurrentPath = path:GetWaypoints()
        CurrentWaypoint = 1
        return true
    end
    
    return false
end

-- Follow current path
local function FollowPath()
    local myChar = LocalPlayer.Character
    if not myChar or not CurrentPath then return false end
    
    local humanoid = myChar:FindFirstChildOfClass("Humanoid")
    local root = myChar:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not root then return false end
    
    if CurrentWaypoint <= #CurrentPath then
        local waypoint = CurrentPath[CurrentWaypoint]
        
        -- Move to waypoint
        humanoid:MoveTo(waypoint.Position)
        
        -- Check if reached waypoint
        local dist = (waypoint.Position - root.Position).Magnitude
        if dist < 4 then
            CurrentWaypoint = CurrentWaypoint + 1
        end
        
        return true
    end
    
    return false
end

-- AI Decision Making
local function AIDecision()
    if not _G.AIEnabled then return end
    
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    -- Priority 1: Evade killer if too close
    local nearestKiller, killerDist = FindNearestKiller()
    if nearestKiller and killerDist < 70 then
        _G.AIState = AIStates.Evading
        
        -- Run away from killer
        if nearestKiller.Character and nearestKiller.Character:FindFirstChild("HumanoidRootPart") then
            local killerPos = nearestKiller.Character.HumanoidRootPart.Position
            local myPos = myChar.HumanoidRootPart.Position
            local awayDir = (myPos - killerPos).Unit
            local awayPos = myPos + (awayDir * 50)
            
            CreatePathTo(awayPos)
        end
        return
    end
    
    -- Priority 2: Heal injured teammate
    local injuredTeammate = FindInjuredTeammate()
    if injuredTeammate and injuredTeammate.Character and injuredTeammate.Character:FindFirstChild("HumanoidRootPart") then
        _G.AIState = AIStates.Healing
        CreatePathTo(injuredTeammate.Character.HumanoidRootPart.Position)
        return
    end
    
    -- Priority 3: Repair generator
    local nearestGen = FindNearestGenerator()
    if nearestGen then
        _G.AIState = AIStates.Repairing
        CreatePathTo(nearestGen:GetPivot().Position)
        return
    end
    
    -- Priority 4: Go to exit gate (if all gens done)
    -- Check if all generators complete
    local allComplete = true
    for _, obj in pairs(Services.Workspace:GetDescendants()) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            local progress = obj:GetAttribute("RepairProgress") or 0
            if progress < 100 then
                allComplete = false
                break
            end
        end
    end
    
    if allComplete then
        _G.AIState = AIStates.Escaping
        -- Find exit gate
        for _, obj in pairs(Services.Workspace:GetDescendants()) do
            if obj.Name == "ExitGate" or obj.Name == "Gate" then
                CreatePathTo(obj:GetPivot().Position)
                return
            end
        end
    end
    
    -- Default: Idle
    _G.AIState = AIStates.Idle
end

-- Enable AI
local function EnableAI()
    if AIConnection then return end
    
    print("[AI Bot] Enabling...")
    
    local lastDecision = 0
    
    AIConnection = Services.RunService.Heartbeat:Connect(function()
        if not _G.AIEnabled then return end
        
        local myChar = LocalPlayer.Character
        if not myChar then return end
        
        local humanoid = myChar:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        -- Set AI speed
        humanoid.WalkSpeed = _G.AISpeed
        
        -- Make decision every 2 seconds
        if tick() - lastDecision > 2 then
            lastDecision = tick()
            AIDecision()
        end
        
        -- Follow path
        if CurrentPath then
            local stillMoving = FollowPath()
            if not stillMoving then
                CurrentPath = nil
                CurrentWaypoint = 1
            end
        end
    end)
    
    print("[AI Bot] ✅ Enabled")
end

-- Disable AI
local function DisableAI()
    if AIConnection then
        AIConnection:Disconnect()
        AIConnection = nil
    end
    
    CurrentPath = nil
    CurrentWaypoint = 1
    _G.AIState = AIStates.Idle
    
    -- Reset speed
    local myChar = LocalPlayer.Character
    if myChar then
        local humanoid = myChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
    
    print("[AI Bot] ✅ Disabled")
end


-- ========================================
-- BOOST ALL GEN (GROUP PROJECT)
-- ========================================

_G.BoostAllGenEnabled = false

local function BoostAllGenerators()
    print("[Boost Gen] Starting boost...")
    
    local boosted = 0
    local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        Library:Notify("❌ Remotes not found", 2)
        return
    end
    
    local genRemotes = remotes:FindFirstChild("Generator")
    if not genRemotes then
        Library:Notify("❌ Generator remotes not found", 2)
        return
    end
    
    local projectRemote = genRemotes:FindFirstChild("ProjectRemote")
    local skillCheckRemote = genRemotes:FindFirstChild("SkillCheckResultEvent")
    
    if not projectRemote or not skillCheckRemote then
        Library:Notify("❌ Required remotes not found", 2)
        return
    end
    
    -- Find all active generators
    for _, obj in pairs(Services.Workspace:GetDescendants()) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            local progress = obj:GetAttribute("RepairProgress") or 0
            
            -- Only boost generators in progress (0-99%)
            if progress > 0 and progress < 100 then
                pcall(function()
                    -- Fire 12x rapid skillcheck (Group Project mechanic)
                    for i = 1, 12 do
                        projectRemote:FireServer(obj)
                        task.wait(0.045)  -- 45ms delay
                        skillCheckRemote:FireServer(true)  -- Perfect skillcheck
                        task.wait(0.045)
                    end
                    
                    boosted = boosted + 1
                    print(string.format("[Boost Gen] Boosted generator #%d (%.0f%%)", boosted, progress))
                end)
                
                task.wait(0.1)  -- Small delay between generators
            end
        end
    end
    
    Library:Notify(string.format("✅ Boosted %d generators!", boosted), 3)
    print(string.format("[Boost Gen] Completed - %d generators boosted", boosted))
end

-- Hotkey for Boost Gen (B key)
Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if _G.BoostAllGenEnabled and input.KeyCode == Enum.KeyCode.B then
        BoostAllGenerators()
    end
end)

-- ========================================
-- MOONWALK SYSTEM
-- ========================================

_G.MoonwalkEnabled = false
_G.MoonwalkSpeed = 11
_G.MoonwalkBoost = 1.08
local MoonwalkConnection = nil
local MoonwalkAmount = 52

local function EnableMoonwalk()
    if MoonwalkConnection then return end
    
    print("[Moonwalk] Enabling...")
    
    local zigzagOffset = 0
    
    MoonwalkConnection = Services.RunService.Heartbeat:Connect(function(dt)
        if not _G.MoonwalkEnabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not root then return end
        
        -- Apply speed boost
        if humanoid.MoveDirection.Magnitude > 0 then
            local baseSpeed = 16
            humanoid.WalkSpeed = baseSpeed * _G.MoonwalkBoost
            
            -- Zigzag calculation
            zigzagOffset = zigzagOffset + (_G.MoonwalkSpeed * dt)
            local zigzagValue = math.sin(zigzagOffset) * (MoonwalkAmount / 100)
            
            -- Apply zigzag to CFrame
            local moveDir = humanoid.MoveDirection
            if moveDir.Magnitude > 0 then
                local rightVector = root.CFrame.RightVector
                local offset = rightVector * zigzagValue
                
                root.CFrame = root.CFrame + offset
            end
        end
    end)
    
    print("[Moonwalk] ✅ Enabled")
end

local function DisableMoonwalk()
    if MoonwalkConnection then
        MoonwalkConnection:Disconnect()
        MoonwalkConnection = nil
    end
    
    -- Reset speed
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
    
    print("[Moonwalk] ✅ Disabled")
end

-- Hotkey for Moonwalk (R key)
Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.R then
        _G.MoonwalkEnabled = not _G.MoonwalkEnabled
        
        if _G.MoonwalkEnabled then
            EnableMoonwalk()
            Library:Notify("🌙 Moonwalk: ON", 1.5)
        else
            DisableMoonwalk()
            Library:Notify("🌙 Moonwalk: OFF", 1.5)
        end
    end
end)

-- ========================================
-- VISUALS TAB - NEW FEATURES
-- ========================================

local VisualsGroupBox = Tabs.Visuals:AddLeftGroupbox("Visual Effects", "eye")

VisualsGroupBox:AddToggle("PotatoMode", {
    Text = "Potato Mode",
    Default = false,
    Callback = function(Value)
        _G.PotatoModeEnabled = Value
        
        if Value then
            EnablePotatoMode()
            Library:Notify("🥔 Potato Mode: ON", 2)
        else
            DisablePotatoMode()
            Library:Notify("🥔 Potato Mode: OFF", 2)
        end
    end
})

VisualsGroupBox:AddToggle("AntiBlind", {
    Text = "Anti-Blind",
    Default = false,
    Callback = function(Value)
        for _, effect in pairs(Services.Lighting:GetChildren()) do
            if effect:IsA("BlurEffect") then
                effect.Enabled = not Value
            elseif effect:IsA("ColorCorrectionEffect") then
                effect.Enabled = not Value
            end
        end
        
        Library:Notify("Anti-Blind: " .. (Value and "ON" or "OFF"), 1)
    end
})

VisualsGroupBox:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = false,
    Callback = function(Value)
        if Value then
            Services.Lighting.Brightness = 2
            Services.Lighting.ClockTime = 12
            Services.Lighting.FogEnd = 100000
            Services.Lighting.GlobalShadows = false
        else
            Services.Lighting.Brightness = 1
            Services.Lighting.ClockTime = 14
            Services.Lighting.FogEnd = 1000
            Services.Lighting.GlobalShadows = true
        end
        
        Library:Notify("Fullbright: " .. (Value and "ON" or "OFF"), 1)
    end
})

-- ========================================
-- ESP TAB
-- ========================================

-- ========================================
-- FINAL INITIALIZATION
-- ========================================

print("[WolfHub] All features loaded!")


-- ========================================
-- AUTOMATION TAB (NEW)
-- ========================================

local AutomationTab = Window:AddTab("Automation", "zap")

-- AI Auto Play
local AIGroupBox = AutomationTab:AddLeftGroupbox("AI Auto Play", "cpu")

AIGroupBox:AddToggle("AIEnable", {
    Text = "Smart AI Bot",
    Default = false,
    Callback = function(Value)
        _G.AIEnabled = Value
        
        if Value then
            EnableAI()
            Library:Notify("🤖 AI Bot: ON", 2)
        else
            DisableAI()
            Library:Notify("🤖 AI Bot: OFF", 2)
        end
    end
})

AIGroupBox:AddSlider("AISpeed", {
    Text = "AI Speed",
    Default = 17,
    Min = 16,
    Max = 25,
    Rounding = 1,
    Callback = function(Value)
        _G.AISpeed = Value
    end
})

AIGroupBox:AddLabel("Current State:")
local AIStateLabel = AIGroupBox:AddLabel(_G.AIState)

task.spawn(function()
    while task.wait(0.5) do
        AIStateLabel:SetText("State: " .. _G.AIState)
    end
end)

-- Generator Automation
local GenGroupBox = AutomationTab:AddLeftGroupbox("Generator", "zap")

GenGroupBox:AddToggle("BoostAllGen", {
    Text = "Boost All Gen (B key)",
    Default = false,
    Callback = function(Value)
        _G.BoostAllGenEnabled = Value
        Library:Notify("Boost Gen: " .. (Value and "ON" or "OFF"), 2)
    end
})

GenGroupBox:AddButton({
    Text = "Boost Now",
    Func = function()
        BoostAllGenerators()
    end
})

-- Moonwalk
local MoonwalkGroupBox = AutomationTab:AddRightGroupbox("Moonwalk", "wind")

MoonwalkGroupBox:AddToggle("MoonwalkEnable", {
    Text = "Moonwalk (R key)",
    Default = false,
    Callback = function(Value)
        _G.MoonwalkEnabled = Value
        
        if Value then
            EnableMoonwalk()
            Library:Notify("🌙 Moonwalk: ON", 2)
        else
            DisableMoonwalk()
            Library:Notify("🌙 Moonwalk: OFF", 2)
        end
    end
})

MoonwalkGroupBox:AddSlider("MoonwalkSpeed", {
    Text = "Zigzag Speed",
    Default = 11,
    Min = 5,
    Max = 50,
    Rounding = 1,
    Callback = function(Value)
        _G.MoonwalkSpeed = Value
    end
})

MoonwalkGroupBox:AddSlider("MoonwalkBoost", {
    Text = "Speed Boost",
    Default = 108,
    Min = 100,
    Max = 150,
    Rounding = 1,
    Callback = function(Value)
        _G.MoonwalkBoost = Value / 100
    end
})

-- ========================================
-- ANTI SYSTEMS TAB (SETTINGS)
-- ========================================

local AntiSystemsGroupBox = Tabs.Settings:AddLeftGroupbox("Anti Systems", "shield")

AntiSystemsGroupBox:AddToggle("AntiLogger", {
    Text = "Anti-Logger",
    Default = true,
    Callback = function(Value)
        _G.AntiLoggerEnabled = Value
        Library:Notify("Anti-Logger: " .. (Value and "ON" or "OFF"), 2)
    end
})

AntiSystemsGroupBox:AddToggle("AntiAura", {
    Text = "Anti-Aura",
    Default = false,
    Callback = function(Value)
        _G.AntiAuraEnabled = Value
        
        if Value and not AntiAuraHooked then
            SetupAntiAura()
        end
        
        Library:Notify("Anti-Aura: " .. (Value and "ON" or "OFF"), 2)
    end
})

-- ========================================
-- FINAL INITIALIZATION
-- ========================================

print("[WolfHub] All features loaded!")

-- Auto-update ESP (handled by startESP and new Melonz ESP system)

-- Setup Save Manager and Theme Manager at end of file
SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

ThemeManager:SetFolder("WolfFamilyHub")
SaveManager:SetFolder("WolfFamilyHub/Fix-28-RELEASE")

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- Load autoload config
task.spawn(function()
    task.wait(1)
    SaveManager:LoadAutoloadConfig()
end)

print("==============================================")
print("[WolfHub] ✅ Fix-28 Early ULTIMATE Edition Ready!")
print("[WolfHub] 🆕 NEW FEATURES:")
print("  • Smart AI Auto Play")
print("  • Moonwalk System")
print("  • Boost All Gen")
print("  • Anti-Logger")
print("  • Anti-Aura")
print("  • Potato Mode")
print("==============================================")

Library:Notify("🐺 WolfFamily Hub Loaded!", 3)

