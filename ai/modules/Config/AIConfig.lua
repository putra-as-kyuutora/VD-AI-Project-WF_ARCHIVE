-- ============================================
-- AIConfig.lua
-- AI behavior parameters and tuning
-- ============================================

local AIConfig = {}

-- Vision System
AIConfig.Vision = {
    Range = 150,              -- Studs
    FOV = 120,                -- Field of view in degrees
    UpdateRate = 0.1,         -- Seconds between vision updates
    RaycastParams = {
        FilterType = Enum.RaycastFilterType.Blacklist,
        IgnoreWater = true
    }
}

-- Movement System
AIConfig.Movement = {
    WalkSpeed = 16,           -- Default walk speed
    RunSpeed = 20,            -- Sprint speed
    PathRefreshRate = 0.5,    -- Seconds between path recalculation
    StuckTimeout = 3,         -- Seconds before considering bot stuck
    StuckDistance = 2,        -- Studs moved to not be considered stuck
    WaypointReachedDistance = 5 -- Studs to consider waypoint reached
}

-- Combat System
AIConfig.Combat = {
    AttackRange = 5,          -- Studs (melee range for killer)
    ShootRange = 100,         -- Studs (if using ranged weapons)
    AttackCooldown = 1.5,     -- Seconds between attacks
    AimPrediction = true,     -- Predict target movement
    PreferHeadshots = false   -- Aim for head (if applicable)
}

-- Survival System (for Survivor bots)
AIConfig.Survival = {
    GeneratorRepairRange = 5,        -- Distance to start repairing
    GeneratorPriority = "nearest",   -- "nearest", "lowest_progress", "safest"
    UnhookRange = 5,                 -- Distance to unhook teammate
    HealRange = 5,                   -- Distance to heal teammate
    FleeHealthThreshold = 30,        -- Health % to start fleeing
    HideHealthThreshold = 20,        -- Health % to hide
    UseWindowsWhenChased = true,
    UsePalletsWhenChased = true
}

-- Decision Making
AIConfig.Decision = {
    UpdateRate = 0.2,         -- Seconds between decision updates
    ReactionTime = 0.1,       -- Simulated human reaction delay
    Aggression = 0.7,         -- 0-1, how aggressive (higher = more aggressive)
    Caution = 0.5,            -- 0-1, how cautious (higher = more cautious)
    Teamwork = 0.8,           -- 0-1, tendency to help teammates
}

-- Sensor System
AIConfig.Sensor = {
    ScanRange = 100,          -- Studs to scan for objects
    ScanRate = 0.3,           -- Seconds between scans
    PriorityRadius = 30,      -- Studs for high-priority objects
}

-- State Priorities (for Survivors)
AIConfig.StatePriorities = {
    -- Higher number = higher priority
    FLEE = 100,               -- Fleeing from killer
    HEAL_SELF = 90,           -- Healing self when injured
    UNHOOK_TEAMMATE = 85,     -- Unhooking hooked teammate
    HIDE = 80,                -- Hiding when killer nearby
    REPAIR_GENERATOR = 70,    -- Repairing generators
    HEAL_TEAMMATE = 60,       -- Healing injured teammate
    ESCAPE = 95,              -- Escaping through gate
    EXPLORE = 40,             -- Exploring map
    IDLE = 10                 -- Idle/waiting
}

-- Killer State Priorities
AIConfig.KillerPriorities = {
    CHASE = 100,              -- Chasing survivor
    ATTACK = 110,             -- Attacking survivor in range
    PATROL = 50,              -- Patrolling generators
    CHECK_NOISE = 70,         -- Checking noise/notification
    HOOK_SURVIVOR = 90,       -- Hooking downed survivor
    SEARCH = 60               -- Searching for survivors
}

-- Debug Options
AIConfig.Debug = {
    ShowPathfinding = false,  -- Visualize pathfinding
    ShowVision = false,       -- Show vision cone
    ShowDecisions = true,     -- Print decisions to console
    ShowDetections = false    -- Print detected objects
}

return AIConfig
