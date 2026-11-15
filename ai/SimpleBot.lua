-- ============================================
-- Simple Violence District Bot
-- Basic movement with obstacle avoidance
-- ============================================

print("🤖 Loading Violence District AI Bot...")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

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
    Debug = true
}

-- ════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════
local State = {
    IsActive = false,
    CurrentPath = nil,
    CurrentWaypointIndex = 0,
    TargetPosition = nil,
    LastPathTime = 0,
    LastUpdateTime = 0
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
        AgentCanJump = true,
        WaypointSpacing = 4,
        Costs = {
            Water = math.huge
        }
    })
    
    local success, errorMsg = pcall(function()
        path:ComputeAsync(RootPart.Position, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        return path
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
-- MOVEMENT
-- ════════════════════════════════════════

local function StopMoving()
    Humanoid:Move(Vector3.new(0, 0, 0))
    State.CurrentPath = nil
    State.CurrentWaypointIndex = 0
    DebugPrint("Stopped moving")
end

local function StartPatrol()
    local targetPos = GetRandomPosition()
    State.TargetPosition = targetPos
    State.LastPathTime = tick()
    
    DebugPrint("New patrol target: " .. tostring(targetPos))
    
    local path = CreatePath(targetPos)
    if path then
        State.CurrentPath = path
        State.CurrentWaypointIndex = 1
        DebugPrint("Path created with " .. #path:GetWaypoints() .. " waypoints")
    else
        -- Fallback: direct movement
        DebugPrint("Using direct movement fallback")
        local direction = (targetPos - RootPart.Position).Unit
        Humanoid:Move(direction)
    end
end

local function UpdatePathfinding()
    if not State.CurrentPath then
        return false
    end
    
    local waypoints = State.CurrentPath:GetWaypoints()
    
    -- Check if finished path
    if State.CurrentWaypointIndex > #waypoints then
        DebugPrint("Reached end of path")
        StopMoving()
        return false
    end
    
    local currentWaypoint = waypoints[State.CurrentWaypointIndex]
    local distance = (currentWaypoint.Position - RootPart.Position).Magnitude
    
    -- Check if reached current waypoint
    if distance <= Config.WaypointReachedDistance then
        State.CurrentWaypointIndex = State.CurrentWaypointIndex + 1
        
        if State.CurrentWaypointIndex > #waypoints then
            DebugPrint("Path completed!")
            StopMoving()
            return false
        end
        
        currentWaypoint = waypoints[State.CurrentWaypointIndex]
        
        -- Handle jump
        if currentWaypoint.Action == Enum.PathWaypointAction.Jump then
            DebugPrint("Jumping!")
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    
    -- Move towards current waypoint
    local direction = (currentWaypoint.Position - RootPart.Position).Unit
    Humanoid:Move(direction)
    
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
    
    local currentTime = tick()
    
    -- Rate limiting
    if currentTime - State.LastUpdateTime < Config.UpdateRate then
        return
    end
    State.LastUpdateTime = currentTime
    
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
    
    -- Update pathfinding if we have a path
    if State.CurrentPath then
        local isMoving = UpdatePathfinding()
        
        if not isMoving then
            -- Path finished, wait a bit then get new target
            wait(1)
            StartPatrol()
        end
    else
        -- No path, check if we're stuck or need new target
        if CheckIfStuck() or not State.TargetPosition then
            StartPatrol()
        end
        
        -- Refresh path periodically
        if currentTime - State.LastPathTime > Config.PathRefreshInterval then
            if State.TargetPosition and GetDistanceToTarget() > Config.WaypointReachedDistance then
                DebugPrint("Refreshing path...")
                local path = CreatePath(State.TargetPosition)
                if path then
                    State.CurrentPath = path
                    State.CurrentWaypointIndex = 1
                    State.LastPathTime = currentTime
                end
            else
                -- Reached target, get new one
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
print("  BotConfig.Debug = true/false")
print("")

-- Auto start
wait(1)
StartBot()
