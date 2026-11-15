-- ============================================
-- MovementController.lua
-- Handles all movement, pathfinding, and navigation
-- ============================================

local MovementController = {}
MovementController.__index = MovementController

-- Constructor
function MovementController.new(character, aiConfig, gameConfig)
    local self = setmetatable({}, MovementController)
    
    self.character = character
    self.aiConfig = aiConfig
    self.gameConfig = gameConfig
    self.pathfindingService = gameConfig.Services.PathfindingService
    
    -- Movement state
    self.currentPath = nil
    self.currentWaypointIndex = 0
    self.isMoving = false
    self.targetPosition = nil
    self.lastPathTime = 0
    self.stuckCheckPosition = nil
    self.stuckCheckTime = 0
    
    -- Movement parameters
    self.walkSpeed = aiConfig.Movement.WalkSpeed
    self.runSpeed = aiConfig.Movement.RunSpeed
    self.pathRefreshRate = aiConfig.Movement.PathRefreshRate
    self.waypointReachedDistance = aiConfig.Movement.WaypointReachedDistance
    
    return self
end

-- Get humanoid from character
function MovementController:GetHumanoid()
    if not self.character then return nil end
    return self.character:FindFirstChild(self.gameConfig.CharacterParts.HUMANOID)
end

-- Get root part from character
function MovementController:GetRootPart()
    if not self.character then return nil end
    return self.character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
end

-- Get current position
function MovementController:GetPosition()
    local rootPart = self:GetRootPart()
    if rootPart then
        return rootPart.Position
    end
    return nil
end

-- Set walk speed
function MovementController:SetWalkSpeed(speed)
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

-- Sprint (increase speed)
function MovementController:Sprint()
    self:SetWalkSpeed(self.runSpeed)
end

-- Walk (normal speed)
function MovementController:Walk()
    self:SetWalkSpeed(self.walkSpeed)
end

-- Stop moving
function MovementController:Stop()
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid:Move(Vector3.new(0, 0, 0))
    end
    
    self.isMoving = false
    self.currentPath = nil
    self.targetPosition = nil
end

-- Simple move towards position (no pathfinding)
function MovementController:MoveTowards(targetPosition)
    local humanoid = self:GetHumanoid()
    local currentPosition = self:GetPosition()
    
    if not humanoid or not currentPosition then return false end
    
    local direction = (targetPosition - currentPosition).Unit
    humanoid:Move(direction)
    
    self.isMoving = true
    self.targetPosition = targetPosition
    
    return true
end

-- Create path to target position
function MovementController:CreatePath(targetPosition)
    local currentPosition = self:GetPosition()
    if not currentPosition then return nil end
    
    -- Create path object
    local path = self.pathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4,
        Costs = {
            Water = math.huge, -- Avoid water
            DangerZone = 10    -- Avoid dangerous areas (if tagged)
        }
    })
    
    -- Compute path
    local success, errorMessage = pcall(function()
        path:ComputeAsync(currentPosition, targetPosition)
    end)
    
    if not success then
        warn("[MovementController] Path computation failed: " .. tostring(errorMessage))
        return nil
    end
    
    if path.Status == Enum.PathStatus.Success then
        return path
    else
        warn("[MovementController] Path status: " .. tostring(path.Status))
        return nil
    end
end

-- Move to position using pathfinding
function MovementController:MoveTo(targetPosition, usePathfinding)
    usePathfinding = usePathfinding ~= false -- Default true
    
    if not usePathfinding then
        -- Simple direct movement
        return self:MoveTowards(targetPosition)
    end
    
    -- Check if we need to refresh path
    local currentTime = tick()
    if self.currentPath and (currentTime - self.lastPathTime) < self.pathRefreshRate then
        -- Use existing path
        return true
    end
    
    -- Create new path
    local path = self:CreatePath(targetPosition)
    if not path then
        -- Fallback to direct movement
        return self:MoveTowards(targetPosition)
    end
    
    self.currentPath = path
    self.currentWaypointIndex = 1
    self.targetPosition = targetPosition
    self.lastPathTime = currentTime
    self.isMoving = true
    
    return true
end

-- Update pathfinding (call this in a loop)
function MovementController:UpdatePath()
    if not self.isMoving or not self.currentPath then
        return false
    end
    
    local humanoid = self:GetHumanoid()
    local rootPart = self:GetRootPart()
    
    if not humanoid or not rootPart then
        self:Stop()
        return false
    end
    
    local waypoints = self.currentPath:GetWaypoints()
    
    -- Check if reached target
    if self.currentWaypointIndex > #waypoints then
        self:Stop()
        return false
    end
    
    local currentWaypoint = waypoints[self.currentWaypointIndex]
    local distance = (currentWaypoint.Position - rootPart.Position).Magnitude
    
    -- Check if reached current waypoint
    if distance <= self.waypointReachedDistance then
        self.currentWaypointIndex = self.currentWaypointIndex + 1
        
        if self.currentWaypointIndex > #waypoints then
            self:Stop()
            return false
        end
        
        currentWaypoint = waypoints[self.currentWaypointIndex]
        
        -- Handle jump waypoint
        if currentWaypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    
    -- Move towards current waypoint
    local direction = (currentWaypoint.Position - rootPart.Position).Unit
    humanoid:Move(direction)
    
    return true
end

-- Check if stuck
function MovementController:IsStuck()
    if not self.isMoving then return false end
    
    local currentPosition = self:GetPosition()
    if not currentPosition then return false end
    
    local currentTime = tick()
    
    -- Initialize stuck check
    if not self.stuckCheckPosition or (currentTime - self.stuckCheckTime) >= self.aiConfig.Movement.StuckTimeout then
        self.stuckCheckPosition = currentPosition
        self.stuckCheckTime = currentTime
        return false
    end
    
    -- Check if moved enough
    local distanceMoved = (currentPosition - self.stuckCheckPosition).Magnitude
    
    if distanceMoved < self.aiConfig.Movement.StuckDistance then
        -- Stuck!
        return true
    end
    
    -- Update stuck check
    self.stuckCheckPosition = currentPosition
    self.stuckCheckTime = currentTime
    
    return false
end

-- Handle being stuck (try to unstuck)
function MovementController:HandleStuck()
    warn("[MovementController] Bot is stuck! Attempting to recover...")
    
    -- Stop current path
    self:Stop()
    
    -- Try jumping
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    -- Reset stuck check
    self.stuckCheckPosition = nil
    self.stuckCheckTime = 0
    
    -- Wait a bit before continuing
    task.wait(0.5)
end

-- Move to player
function MovementController:MoveToPlayer(targetPlayer, usePathfinding)
    if not targetPlayer or not targetPlayer.Character then return false end
    
    local targetRoot = targetPlayer.Character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
    if not targetRoot then return false end
    
    return self:MoveTo(targetRoot.Position, usePathfinding)
end

-- Move to object
function MovementController:MoveToObject(targetObject, usePathfinding)
    if not targetObject then return false end
    
    local targetPosition = nil
    
    if targetObject:IsA("BasePart") then
        targetPosition = targetObject.Position
    elseif targetObject:IsA("Model") then
        local primaryPart = targetObject.PrimaryPart or targetObject:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            targetPosition = primaryPart.Position
        end
    end
    
    if not targetPosition then return false end
    
    return self:MoveTo(targetPosition, usePathfinding)
end

-- Patrol (move to random nearby position)
function MovementController:Patrol(patrolRadius)
    patrolRadius = patrolRadius or 50
    
    local currentPosition = self:GetPosition()
    if not currentPosition then return false end
    
    -- Generate random position nearby
    local randomAngle = math.random() * math.pi * 2
    local randomDistance = math.random() * patrolRadius
    
    local targetPosition = currentPosition + Vector3.new(
        math.cos(randomAngle) * randomDistance,
        0,
        math.sin(randomAngle) * randomDistance
    )
    
    return self:MoveTo(targetPosition, true)
end

-- Flee from position (run away)
function MovementController:FleeFrom(dangerPosition, fleeDistance)
    fleeDistance = fleeDistance or 30
    
    local currentPosition = self:GetPosition()
    if not currentPosition then return false end
    
    -- Calculate direction away from danger
    local awayDirection = (currentPosition - dangerPosition).Unit
    local fleeTarget = currentPosition + (awayDirection * fleeDistance)
    
    -- Sprint while fleeing
    self:Sprint()
    
    return self:MoveTo(fleeTarget, true)
end

-- Check if reached target position
function MovementController:HasReachedTarget(threshold)
    threshold = threshold or self.waypointReachedDistance
    
    if not self.targetPosition then return true end
    
    local currentPosition = self:GetPosition()
    if not currentPosition then return false end
    
    local distance = (currentPosition - self.targetPosition).Magnitude
    return distance <= threshold
end

-- Get movement status
function MovementController:GetStatus()
    return {
        IsMoving = self.isMoving,
        TargetPosition = self.targetPosition,
        HasPath = self.currentPath ~= nil,
        CurrentWaypoint = self.currentWaypointIndex,
        IsStuck = self:IsStuck()
    }
end

return MovementController
