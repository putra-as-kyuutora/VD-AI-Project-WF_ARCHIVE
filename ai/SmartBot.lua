-- ============================================
-- Smart Violence District Bot v2.0
-- Priority-based decision making AI
-- ============================================

print("🧠 Loading Smart AI Bot...")

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
    -- Speed
    WalkSpeed = 16,
    FleeSpeed = 20,
    
    -- Distances
    KillerDetectionRange = 100,
    KillerFleeDistance = 70,
    GeneratorRange = 100,
    TeammateRange = 80,
    
    -- Patrol
    PatrolRadius = 40,
    WaypointReachedDistance = 4,
    
    -- Update rates
    DecisionInterval = 2,
    PathRefreshInterval = 3,
    
    -- Debug
    Debug = true,
    ShowState = true
}

-- ════════════════════════════════════════
-- AI STATES (Priority System)
-- ════════════════════════════════════════
local AIStates = {
    IDLE = "Idle",
    PATROL = "Patrol",
    FLEEING = "Fleeing",          -- Priority 1 (highest)
    HIDING = "Hiding",             -- Priority 2
    HEALING_TEAMMATE = "Healing",  -- Priority 3
    REPAIRING = "Repairing",       -- Priority 4
    ESCAPING = "Escaping",         -- Priority 5
    EXPLORING = "Exploring"        -- Priority 6 (lowest)
}

-- ════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════
local State = {
    IsActive = false,
    CurrentState = AIStates.IDLE,
    CurrentPath = nil,
    CurrentWaypointIndex = 1,
    TargetPosition = nil,
    TargetObject = nil,
    LastDecisionTime = 0,
    LastPathTime = 0,
    
    -- Detected objects cache
    NearbyKillers = {},
    NearbyGenerators = {},
    NearbyTeammates = {},
    NearbyGates = {},
    
    LastScanTime = 0,
    ScanInterval = 1  -- Scan every 1 second
}

-- ════════════════════════════════════════
-- HELPER FUNCTIONS
-- ════════════════════════════════════════

local function DebugPrint(message)
    if Config.Debug then
        print("[SmartAI] " .. message)
    end
end

local function SetState(newState)
    if State.CurrentState ~= newState then
        DebugPrint("State changed: " .. State.CurrentState .. " → " .. newState)
        State.CurrentState = newState
    end
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- ════════════════════════════════════════
-- DETECTION SYSTEM
-- ════════════════════════════════════════

local function IsKiller(player)
    if not player or not player.Team then return false end
    local teamName = player.Team.Name:lower()
    return teamName:find("killer") ~= nil
end

local function IsSurvivor(player)
    if not player or not player.Team then return false end
    local teamName = player.Team.Name:lower()
    return teamName:find("survivor") ~= nil
end

local function IsMyTeam(player)
    if not player or not player.Team or not LocalPlayer.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function ScanForKillers()
    local killers = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and IsKiller(player) then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChild("Humanoid")
            
            if targetRoot and targetHum and targetHum.Health > 0 then
                local distance = GetDistance(RootPart.Position, targetRoot.Position)
                
                if distance <= Config.KillerDetectionRange then
                    table.insert(killers, {
                        Player = player,
                        Character = player.Character,
                        Position = targetRoot.Position,
                        Distance = distance
                    })
                end
            end
        end
    end
    
    -- Sort by distance (nearest first)
    table.sort(killers, function(a, b) return a.Distance < b.Distance end)
    
    return killers
end

local function ScanForGenerators()
    local generators = {}
    local map = workspace:FindFirstChild("Map")
    
    if not map then return generators end
    
    for _, obj in pairs(map:GetDescendants()) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            local progress = obj:GetAttribute("RepairProgress") or 0
            
            -- Only incomplete generators
            if progress < 100 then
                local genPos = obj:GetPivot().Position
                local distance = GetDistance(RootPart.Position, genPos)
                
                if distance <= Config.GeneratorRange then
                    table.insert(generators, {
                        Object = obj,
                        Position = genPos,
                        Distance = distance,
                        Progress = progress
                    })
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(generators, function(a, b) return a.Distance < b.Distance end)
    
    return generators
end

local function ScanForTeammates()
    local teammates = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and IsMyTeam(player) then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChild("Humanoid")
            
            if targetRoot and targetHum then
                local distance = GetDistance(RootPart.Position, targetRoot.Position)
                local healthPercent = (targetHum.Health / targetHum.MaxHealth) * 100
                
                if distance <= Config.TeammateRange and healthPercent < 50 then
                    table.insert(teammates, {
                        Player = player,
                        Character = player.Character,
                        Position = targetRoot.Position,
                        Distance = distance,
                        HealthPercent = healthPercent,
                        NeedsHelp = healthPercent < 50
                    })
                end
            end
        end
    end
    
    -- Sort by health (lowest first)
    table.sort(teammates, function(a, b) return a.HealthPercent < b.HealthPercent end)
    
    return teammates
end

local function ScanForExitGates()
    local gates = {}
    local map = workspace:FindFirstChild("Map")
    
    if not map then return gates end
    
    for _, obj in pairs(map:GetDescendants()) do
        if (obj.Name == "Gate" or obj.Name == "ExitGate") and obj:IsA("Model") then
            local gatePos = obj:GetPivot().Position
            local distance = GetDistance(RootPart.Position, gatePos)
            
            table.insert(gates, {
                Object = obj,
                Position = gatePos,
                Distance = distance
            })
        end
    end
    
    table.sort(gates, function(a, b) return a.Distance < b.Distance end)
    
    return gates
end

local function ScanEnvironment()
    local currentTime = tick()
    
    -- Rate limit scanning
    if currentTime - State.LastScanTime < State.ScanInterval then
        return
    end
    
    State.LastScanTime = currentTime
    
    -- Scan everything
    State.NearbyKillers = ScanForKillers()
    State.NearbyGenerators = ScanForGenerators()
    State.NearbyTeammates = ScanForTeammates()
    State.NearbyGates = ScanForExitGates()
    
    if Config.Debug then
        DebugPrint(string.format("Scan: %d killers, %d gens, %d teammates, %d gates",
            #State.NearbyKillers, #State.NearbyGenerators, 
            #State.NearbyTeammates, #State.NearbyGates))
    end
end

-- ════════════════════════════════════════
-- PATHFINDING
-- ════════════════════════════════════════

local function CreatePath(targetPosition)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = false,  -- VD has no jump
        WaypointSpacing = 4
    })
    
    local success, errorMsg = pcall(function()
        path:ComputeAsync(RootPart.Position, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    else
        DebugPrint("Path failed: " .. tostring(path.Status))
        return nil
    end
end

local function MoveTo(targetPosition)
    State.TargetPosition = targetPosition
    State.CurrentPath = CreatePath(targetPosition)
    State.CurrentWaypointIndex = 1
    State.LastPathTime = tick()
end

local function FollowPath()
    if not State.CurrentPath then return false end
    
    if State.CurrentWaypointIndex > #State.CurrentPath then
        return false
    end
    
    local waypoint = State.CurrentPath[State.CurrentWaypointIndex]
    local distance = GetDistance(waypoint.Position, RootPart.Position)
    
    -- Check if reached waypoint
    if distance < Config.WaypointReachedDistance then
        State.CurrentWaypointIndex = State.CurrentWaypointIndex + 1
        
        if State.CurrentWaypointIndex > #State.CurrentPath then
            return false
        end
        
        waypoint = State.CurrentPath[State.CurrentWaypointIndex]
    end
    
    -- Move to waypoint (CRITICAL: call every frame!)
    Humanoid:MoveTo(waypoint.Position)
    
    return true
end

-- ════════════════════════════════════════
-- AI DECISION MAKING (Priority System)
-- ════════════════════════════════════════

local function GetRandomPatrolPosition()
    local angle = math.random() * math.pi * 2
    local distance = math.random(10, Config.PatrolRadius)
    return RootPart.Position + Vector3.new(
        math.cos(angle) * distance, 0, math.sin(angle) * distance
    )
end

local function DecideAction()
    ScanEnvironment()
    
    -- PRIORITY 1: FLEE from nearby killer!
    if #State.NearbyKillers > 0 then
        local nearestKiller = State.NearbyKillers[1]
        
        if nearestKiller.Distance < Config.KillerFleeDistance then
            SetState(AIStates.FLEEING)
            Humanoid.WalkSpeed = Config.FleeSpeed
            
            -- Calculate flee position (away from killer)
            local awayDir = (RootPart.Position - nearestKiller.Position).Unit
            local fleePos = RootPart.Position + (awayDir * 50)
            
            MoveTo(fleePos)
            DebugPrint("FLEEING from killer! Distance: " .. math.floor(nearestKiller.Distance))
            return
        end
    end
    
    -- Back to normal speed if not fleeing
    Humanoid.WalkSpeed = Config.WalkSpeed
    
    -- PRIORITY 2: HEAL injured teammate
    if #State.NearbyTeammates > 0 then
        local teammate = State.NearbyTeammates[1]
        
        if teammate.NeedsHelp then
            SetState(AIStates.HEALING_TEAMMATE)
            MoveTo(teammate.Position)
            DebugPrint("Moving to heal teammate: " .. teammate.Player.Name)
            return
        end
    end
    
    -- PRIORITY 3: REPAIR generator
    if #State.NearbyGenerators > 0 then
        local nearestGen = State.NearbyGenerators[1]
        
        SetState(AIStates.REPAIRING)
        MoveTo(nearestGen.Position)
        DebugPrint("Moving to generator (Progress: " .. math.floor(nearestGen.Progress) .. "%)")
        return
    end
    
    -- PRIORITY 4: ESCAPE if all generators done
    -- TODO: Check if all gens are complete
    
    -- PRIORITY 5: PATROL (default behavior)
    if not State.CurrentPath or State.CurrentState == AIStates.IDLE then
        SetState(AIStates.PATROL)
        local patrolPos = GetRandomPatrolPosition()
        MoveTo(patrolPos)
        DebugPrint("Patrolling...")
    end
end

-- ════════════════════════════════════════
-- MAIN UPDATE LOOP
-- ════════════════════════════════════════

local function Update()
    if not State.IsActive then return end
    
    -- Validate character
    if not Character or not Character.Parent then
        DebugPrint("Character lost")
        State.IsActive = false
        return
    end
    
    if Humanoid.Health <= 0 then
        DebugPrint("Died")
        State.IsActive = false
        return
    end
    
    local currentTime = tick()
    
    -- Make decisions periodically
    if currentTime - State.LastDecisionTime >= Config.DecisionInterval then
        State.LastDecisionTime = currentTime
        DecideAction()
    end
    
    -- Follow path every frame
    if State.CurrentPath then
        local stillMoving = FollowPath()
        
        if not stillMoving then
            DebugPrint("Reached destination")
            State.CurrentPath = nil
            State.CurrentWaypointIndex = 1
        end
    end
end

-- ════════════════════════════════════════
-- START/STOP
-- ════════════════════════════════════════

local function StartBot()
    if State.IsActive then
        print("🤖 Bot already running!")
        return
    end
    
    State.IsActive = true
    State.LastDecisionTime = 0
    Humanoid.WalkSpeed = Config.WalkSpeed
    
    print("════════════════════════════════════════")
    print("🧠 SMART AI BOT STARTED!")
    print("  Mode: Priority-based decision making")
    print("  Team: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "Unknown"))
    print("  States:")
    print("    1. Fleeing (from killer)")
    print("    2. Healing (teammates)")
    print("    3. Repairing (generators)")
    print("    4. Escaping (exit gates)")
    print("    5. Patrolling (exploration)")
    print("  Commands:")
    print("    StopBot() - Stop the bot")
    print("    BotConfig.Debug = false - Disable logs")
    print("════════════════════════════════════════")
    
    DecideAction()
end

local function StopBot()
    if not State.IsActive then
        print("🤖 Bot not running!")
        return
    end
    
    State.IsActive = false
    State.CurrentPath = nil
    Humanoid:MoveTo(RootPart.Position)
    Humanoid.WalkSpeed = 16
    
    print("════════════════════════════════════════")
    print("🛑 SMART AI BOT STOPPED!")
    print("════════════════════════════════════════")
end

-- ════════════════════════════════════════
-- GLOBAL FUNCTIONS
-- ════════════════════════════════════════

_G.StartBot = StartBot
_G.StopBot = StopBot
_G.BotConfig = Config
_G.BotState = State
_G.AIStates = AIStates

-- Status function
_G.BotStatus = function()
    if not State.IsActive then
        print("🤖 Bot: OFFLINE")
        return
    end
    
    print("════════════════════════════════════════")
    print("🤖 BOT STATUS")
    print("  State: " .. State.CurrentState)
    print("  Nearby Killers: " .. #State.NearbyKillers)
    print("  Nearby Generators: " .. #State.NearbyGenerators)
    print("  Nearby Teammates: " .. #State.NearbyTeammates)
    print("  Has Path: " .. tostring(State.CurrentPath ~= nil))
    if State.TargetPosition then
        local dist = GetDistance(RootPart.Position, State.TargetPosition)
        print("  Distance to Target: " .. math.floor(dist) .. " studs")
    end
    print("════════════════════════════════════════")
end

-- ════════════════════════════════════════
-- CONNECT TO GAME LOOP
-- ════════════════════════════════════════

local UpdateConnection = RunService.Heartbeat:Connect(Update)

-- Handle respawn
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    
    DebugPrint("Respawned")
    
    if State.IsActive then
        Humanoid.WalkSpeed = Config.WalkSpeed
        State.LastDecisionTime = 0
        DecideAction()
    end
end)

-- Cleanup
_G.CleanupBot = function()
    State.IsActive = false
    if UpdateConnection then
        UpdateConnection:Disconnect()
    end
    Humanoid:MoveTo(RootPart.Position)
    print("🗑️ Bot cleaned up")
end

-- ════════════════════════════════════════
-- READY
-- ════════════════════════════════════════

print("✅ Smart AI Bot loaded!")
print("📝 Commands:")
print("  StartBot()  - Start the AI")
print("  StopBot()   - Stop the AI")
print("  BotStatus() - Check current status")
print("  CleanupBot() - Remove completely")
print("")
print("⚙️ Config:")
print("  BotConfig.WalkSpeed = 16")
print("  BotConfig.FleeSpeed = 20")
print("  BotConfig.Debug = true/false")
print("")

-- Auto start
wait(1)
StartBot()
