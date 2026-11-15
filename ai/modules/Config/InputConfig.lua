-- ============================================
-- InputConfig.lua
-- Cross-platform input abstraction configuration
-- ============================================

local InputConfig = {}

-- Detect if running on mobile
local UserInputService = game:GetService("UserInputService")
InputConfig.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Input Actions (to be mapped to actual game inputs)
InputConfig.Actions = {
    -- Movement
    MOVE_FORWARD = "MoveForward",
    MOVE_BACKWARD = "MoveBackward",
    MOVE_LEFT = "MoveLeft",
    MOVE_RIGHT = "MoveRight",
    SPRINT = "Sprint",
    CROUCH = "Crouch",
    JUMP = "Jump",
    
    -- Combat
    ATTACK = "Attack",
    SHOOT = "Shoot",
    RELOAD = "Reload",
    AIM = "Aim",
    
    -- Interaction
    INTERACT = "Interact",        -- General interact (repair gen, unhook, etc)
    DROP_PALLET = "DropPallet",
    VAULT_WINDOW = "VaultWindow",
    
    -- Items
    USE_ITEM = "UseItem",
    DROP_ITEM = "DropItem",
    SWITCH_ITEM = "SwitchItem"
}

-- PC Keyboard Mappings
InputConfig.KeyboardMap = {
    [InputConfig.Actions.MOVE_FORWARD] = Enum.KeyCode.W,
    [InputConfig.Actions.MOVE_BACKWARD] = Enum.KeyCode.S,
    [InputConfig.Actions.MOVE_LEFT] = Enum.KeyCode.A,
    [InputConfig.Actions.MOVE_RIGHT] = Enum.KeyCode.D,
    [InputConfig.Actions.SPRINT] = Enum.KeyCode.LeftShift,
    [InputConfig.Actions.CROUCH] = Enum.KeyCode.LeftControl,
    [InputConfig.Actions.JUMP] = Enum.KeyCode.Space,
    [InputConfig.Actions.ATTACK] = Enum.UserInputType.MouseButton1,
    [InputConfig.Actions.INTERACT] = Enum.KeyCode.E,
    [InputConfig.Actions.DROP_PALLET] = Enum.KeyCode.Space,
    [InputConfig.Actions.USE_ITEM] = Enum.KeyCode.Q
}

-- Mobile Touch Button Names (adjust based on your game's mobile UI)
InputConfig.MobileMap = {
    [InputConfig.Actions.SPRINT] = "SprintButton",
    [InputConfig.Actions.CROUCH] = "CrouchButton",
    [InputConfig.Actions.JUMP] = "JumpButton",
    [InputConfig.Actions.ATTACK] = "AttackButton",
    [InputConfig.Actions.INTERACT] = "InteractButton",
    [InputConfig.Actions.DROP_PALLET] = "PalletButton",
    [InputConfig.Actions.USE_ITEM] = "ItemButton"
}

-- Input Methods
InputConfig.InputMethod = {
    KEYBOARD = "Keyboard",
    MOBILE_BUTTON = "MobileButton",
    REMOTE_EVENT = "RemoteEvent",    -- If game uses RemoteEvents for actions
    CONTEXT_ACTION = "ContextAction", -- If game uses ContextActionService
    DIRECT = "Direct"                 -- Direct character manipulation
}

-- Default Input Method (can be changed based on game implementation)
InputConfig.DefaultMethod = InputConfig.InputMethod.KEYBOARD

-- Remote Events (if game uses them for actions)
-- Adjust these paths based on your actual game structure
InputConfig.RemoteEvents = {
    Attack = nil,  -- Example: game.ReplicatedStorage.Remotes.Attack
    Interact = nil,
    UseItem = nil
    -- Add more as needed
}

-- Movement Type
InputConfig.MovementType = {
    PLAYER_MOVE = "PlayerMove",       -- Use Player:Move()
    HUMANOID_MOVE = "HumanoidMove",   -- Use Humanoid:MoveTo()
    CHARACTER_CFrame = "CFrame"       -- Direct CFrame manipulation (not recommended)
}

InputConfig.DefaultMovementType = InputConfig.MovementType.HUMANOID_MOVE

return InputConfig
