-- ============================================
-- GameConfig.lua
-- Configuration for Violence District game constants
-- ============================================

local GameConfig = {}

-- Team Names
GameConfig.Teams = {
    KILLER = "Killer",
    SURVIVORS = "Survivors",
    SPECTATOR = "Spectator"
}

-- Map Object Names (for detection)
GameConfig.Objects = {
    Generator = {
        Name = "Generator",
        Folder = "Map",
        DetectionPart = "HitBox",
        Type = "Interactive"
    },
    Window = {
        Name = "Window",
        Folder = "Map",
        DetectionPart = "inviswall",
        Type = "Traversal"
    },
    Pallet = {
        Names = {"Palletwrong", "PalletAlien"}, -- Multiple possible names
        Folder = "Map",
        DetectionPart = "HumanoidRootPart",
        Type = "Defense"
    },
    Hook = {
        Name = "Hook",
        Folder = "Map",
        DetectionPart = "Model",
        Type = "Danger"
    },
    Gate = {
        Name = "Gate",
        Folder = "Map",
        DetectionPart = "HumanoidRootPart",
        Type = "Escape"
    }
}

-- Game Services
GameConfig.Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    PathfindingService = game:GetService("PathfindingService"),
    UserInputService = game:GetService("UserInputService")
}

-- Map Location
GameConfig.Map = {
    Location = game:GetService("Workspace"):WaitForChild("Map", 10),
    AntiflingingCheck = "Antifling" -- Check if round is active
}

-- Character Parts
GameConfig.CharacterParts = {
    ROOT = "HumanoidRootPart",
    HEAD = "Head",
    HUMANOID = "Humanoid"
}

-- Remotes (if needed)
GameConfig.Remotes = {
    Path = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
}

return GameConfig
