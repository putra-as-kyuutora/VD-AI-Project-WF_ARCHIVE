-- ============================================
-- Simple Violence District Bot
-- Basic movement with obstacle avoidance
-- ============================================

print("🤖 Loading Violence District AI Bot...")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Get PlayerModule for mobile control
local PlayerModule = nil
local PlayerControls = nil

pcall(function()
    PlayerModule = LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 3)
    if PlayerModule then
        local ControlModule = require(PlayerModule:WaitForChild("ControlModule"))
        PlayerControls = ControlModule
    end
end)

-- ════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════
local Config = {
    WalkSpeed = 16,
    RunSpeed = 20,
    PatrolRadius = 50,
    WaypointReachedDistance = 5,
    PathRefreshInterval = 2,
    UpdateRate = 0.1,
    AvoidWalls = true,
    Debug = true,
    MovementMode = "Auto" -- "Auto", "Humanoid", "CFrame", "WalkToPoint"
}

-- ════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════
local State = {
    IsActive = false,
    CurrentPath = nil,  -- Now stores waypoints array, not path object
    CurrentWaypointIndex = 1,
    TargetPosition = nil,
    LastPathTime = 0,
    LastUpdateTime = 0,
    LastDecisionTime = 0
}

-- ════════════════════════════════════════
-- HELPER FUNCTIONS
-- ════════════════════════════════════════

local function DebugPrint(message)
    if Config.Debug then
        print("[Bot] " .. message)
    end
end

local function GetRandomPosition()
    local currentPos = RootPart.Position
    local angle = math.random() * math.pi * 2
    local distance = math.random(10, Config.PatrolRadius)
    
    local targetPos = currentPos + Vector3.new(
        math.cos(angle) * distance,
        0,
        math.sin(angle) * distance
    )
    
    return targetPos
end

local function CreatePath(targetPosition)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = false,  -- Violence District has no jump!
        WaypointSpacing = 4
    })
    
    local success, errorMsg = pcall(function()
        path:ComputeAsync(RootPart.Position, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        -- Return waypoints array (proven working pattern!)
        return path:GetWaypoints()
    else
        DebugPrint("Path failed: " .. tostring(path.Status))
        return nil
    end
end

local function GetDistanceToTarget()
    if not State.TargetPosition then return math.huge end
    return (RootPart.Position - State.TargetPosition).Magnitude
end

-- ════════════════════════════════════════
-- MOVEMENT METHODS
-- ════════════════════════════════════════

local function MoveToPosition_Humanoid(targetPosition)
    -- Method 1: Humanoid:Move (standard)
    local direction = (targetPosition - RootPart.Position).Unit
    Humanoid:Move(direction)
end

local function MoveToPosition_WalkToPoint(targetPosition)
    -- Method 2: WalkToPoint (simple & reliable)
    Humanoid:MoveTo(targetPosition)
end

local function MoveToPosition_CFrame(targetPosition)
    -- Method 3: CFrame (direct but may look robotic)
    local distance = (targetPosition - RootPart.Position).Magnitude
    local speed = Humanoid.WalkSpeed
    
    if distance > 0.5 then
        local direction = (targetPosition - RootPart.Position).Unit
        local moveStep = direction * math.min(speed * Config.UpdateRate, distance)
        RootPart.CFrame = RootPart.CFrame + moveStep
    end
end

local function MoveToPosition_PlayerControls(targetPosition)
    -- Method 4: Use PlayerModule (simulate analog stick)
    if PlayerControls then
        local direction = (targetPosition - RootPart.Position).Unit
        -- This simulates player input
        pcall(function()
            local moveVector = Vector3.new(direction.X, 0, direction.Z)
            -- Try to access player controls
            -- Note: This might not work on all executors
            game:GetService("ContextActionService"):BindAction("BotMove", function() end, false, Enum.KeyCode.W)
        end)
    end
    -- Fallback to humanoid
    MoveToPosition_Humanoid(targetPosition)
end

local function MoveToPosition(targetPosition)
    -- Auto-detect best method
    if Config.MovementMode == "Humanoid" then
        MoveToPosition_Humanoid(targetPosition)
    elseif Config.MovementMode == "WalkToPoint" then
        MoveToPosition_WalkToPoint(targetPosition)
    elseif Config.MovementMode == "CFrame" then
        MoveToPosition_CFrame(targetPosition)
    else
        -- Auto mode: try WalkToPoint first (most reliable)
        MoveToPosition_WalkToPoint(targetPosition)
    end
end

-- ════════════════════════════════════════
-- MOVEMENT
-- ════════════════════════════════════════

local function StopMoving()
    -- Stop all movement methods
    Humanoid:Move(Vector3.new(0, 0, 0))
    
    -- Cancel MoveTo if active
    pcall(function()
        Humanoid:MoveTo(RootPart.Position)
    end)
    
    State.CurrentPath = nil
    State.CurrentWaypointIndex = 0
    DebugPrint("Stopped moving")
end

local function StartPatrol()
    local targetPos = GetRandomPosition()
    State.TargetPosition = targetPos
    State.LastPathTime = tick()
    
    DebugPrint("New patrol target: " .. tostring(targetPos))
    
    local waypoints = CreatePath(targetPos)
    if waypoints then
        State.CurrentPath = waypoints
        State.CurrentWaypointIndex = 1
        DebugPrint("Path created with " .. #waypoints .. " waypoints")
    else
        -- No pathfinding, will use direct movement
        DebugPrint("No path, will move directly")
        State.CurrentPath = nil
    end
end

local function UpdatePathfinding()
    if not State.CurrentPath then
        return false
    end
    
    local waypoints = State.CurrentPath
    
    -- Check if finished path
    if State.CurrentWaypointIndex > #waypoints then
        DebugPrint("Reached end of path")
        return false
    end
    
    local currentWaypoint = waypoints[State.CurrentWaypointIndex]
    local distance = (currentWaypoint.Position - RootPart.Position).Magnitude
    
    -- Check if reached current waypoint
    if distance < Config.WaypointReachedDistance then
        State.CurrentWaypointIndex = State.CurrentWaypointIndex + 1
        DebugPrint("Reached waypoint " .. (State.CurrentWaypointIndex - 1))
        
        if State.CurrentWaypointIndex > #waypoints then
            DebugPrint("Path completed!")
            return false
        end
        
        currentWaypoint = waypoints[State.CurrentWaypointIndex]
    end
    
    -- CRITICAL: Use MoveTo (not Move!) - This is the working method!
    Humanoid:MoveTo(currentWaypoint.Position)
    
    return true
end

local function CheckIfStuck()
    -- Check if target still far but path ended
    local distanceToTarget = GetDistanceToTarget()
    
    if distanceToTarget > 10 and not State.CurrentPath then
        DebugPrint("Seems stuck! Distance to target: " .. math.floor(distanceToTarget))
        return true
    end
    
    return false
end

-- ════════════════════════════════════════
-- MAIN UPDATE LOOP
-- ════════════════════════════════════════

local function Update()
    if not State.IsActive then return end
    
    -- Check if character is valid
    if not Character or not Character.Parent then
        DebugPrint("Character lost, stopping bot")
        State.IsActive = false
        return
    end
    
    if Humanoid.Health <= 0 then
        DebugPrint("Died, stopping bot")
        State.IsActive = false
        return
    end
    
    -- Set speed
    Humanoid.WalkSpeed = Config.WalkSpeed
    
    -- Make decisions every 2 seconds
    local currentTime = tick()
    if currentTime - State.LastDecisionTime > 2 then
        State.LastDecisionTime = currentTime
        
        -- Check if need new path
        if not State.CurrentPath then
            StartPatrol()
        end
    end
    
    -- Follow path (THIS RUNS EVERY FRAME - Critical!)
    if State.CurrentPath then
        local stillMoving = UpdatePathfinding()
        
        if not stillMoving then
            -- Path finished
            State.CurrentPath = nil
            State.CurrentWaypointIndex = 1
            
            -- Get new target after a short wait
            wait(1)
            StartPatrol()
        end
    else
        -- No path, try direct movement to target
        if State.TargetPosition then
            local distance = GetDistanceToTarget()
            if distance > Config.WaypointReachedDistance then
                Humanoid:MoveTo(State.TargetPosition)
            else
                -- Reached target
                StartPatrol()
            end
        end
    end
end

-- ════════════════════════════════════════
-- START/STOP FUNCTIONS
-- ════════════════════════════════════════

local function StartBot()
    if State.IsActive then
        DebugPrint("Bot already running!")
        return
    end
    
    State.IsActive = true
    Humanoid.WalkSpeed = Config.WalkSpeed
    
    print("════════════════════════════════════════")
    print("🤖 BOT STARTED!")
    print("  Walk Speed: " .. Config.WalkSpeed)
    print("  Patrol Radius: " .. Config.PatrolRadius)
    print("  Movement Mode: " .. Config.MovementMode)
    print("  To stop: StopBot()")
    print("════════════════════════════════════════")
    
    -- Start first patrol
    StartPatrol()
end

local function StopBot()
    if not State.IsActive then
        DebugPrint("Bot not running!")
        return
    end
    
    State.IsActive = false
    StopMoving()
    
    print("════════════════════════════════════════")
    print("🛑 BOT STOPPED!")
    print("════════════════════════════════════════")
end

-- ════════════════════════════════════════
-- GLOBAL FUNCTIONS
-- ════════════════════════════════════════

_G.StartBot = StartBot
_G.StopBot = StopBot
_G.BotConfig = Config
_G.BotState = State

-- ════════════════════════════════════════
-- CONNECT TO GAME LOOP
-- ════════════════════════════════════════

local UpdateConnection = RunService.Heartbeat:Connect(Update)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    
    DebugPrint("Character respawned")
    
    if State.IsActive then
        Humanoid.WalkSpeed = Config.WalkSpeed
        StartPatrol()
    end
end)

-- Cleanup function
_G.CleanupBot = function()
    State.IsActive = false
    StopMoving()
    if UpdateConnection then
        UpdateConnection:Disconnect()
    end
    print("🗑️ Bot cleaned up")
end

-- ════════════════════════════════════════
-- AUTO START
-- ════════════════════════════════════════

print("✅ Bot loaded successfully!")
print("📝 Commands:")
print("  StartBot()  - Start the bot")
print("  StopBot()   - Stop the bot")
print("  CleanupBot() - Remove bot completely")
print("")
print("⚙️ Config (edit BotConfig):")
print("  BotConfig.WalkSpeed = 16")
print("  BotConfig.PatrolRadius = 50")
print("  BotConfig.MovementMode = 'WalkToPoint' or 'CFrame' or 'Humanoid'")
print("  BotConfig.Debug = true/false")
print("")
print("💡 Movement Modes:")
print("  'Auto' (default) - Try best method")
print("  'WalkToPoint' - Use Humanoid:MoveTo() (recommended for mobile)")
print("  'CFrame' - Direct position manipulation (smooth)")
print("  'Humanoid' - Standard Humanoid:Move()")
print("")

-- Auto start
wait(1)
StartBot()
