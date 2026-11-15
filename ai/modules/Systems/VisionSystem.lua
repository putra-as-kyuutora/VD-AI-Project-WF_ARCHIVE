-- ============================================
-- VisionSystem.lua
-- Handles vision, line of sight, and raycast detection
-- ============================================

local VisionSystem = {}
VisionSystem.__index = VisionSystem

-- Constructor
function VisionSystem.new(character, aiConfig, gameConfig)
    local self = setmetatable({}, VisionSystem)
    
    self.character = character
    self.aiConfig = aiConfig
    self.gameConfig = gameConfig
    self.workspace = gameConfig.Services.Workspace
    
    -- Vision parameters
    self.visionRange = aiConfig.Vision.Range
    self.fov = aiConfig.Vision.FOV
    self.updateRate = aiConfig.Vision.UpdateRate
    self.lastUpdate = 0
    
    -- Raycast setup
    self.raycastParams = RaycastParams.new()
    self.raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    self.raycastParams.IgnoreWater = true
    
    return self
end

-- Update raycast filter (blacklist bot's own character)
function VisionSystem:UpdateRaycastFilter()
    if self.character then
        self.raycastParams.FilterDescendantsInstances = {self.character}
    end
end

-- Get character's head position (camera/eye position)
function VisionSystem:GetEyePosition()
    if not self.character then return nil end
    
    local head = self.character:FindFirstChild(self.gameConfig.CharacterParts.HEAD)
    if head then
        return head.Position
    end
    
    local rootPart = self.character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
    if rootPart then
        return rootPart.Position + Vector3.new(0, 2, 0) -- Approximate head height
    end
    
    return nil
end

-- Get character's look direction
function VisionSystem:GetLookDirection()
    if not self.character then return Vector3.new(0, 0, -1) end
    
    local rootPart = self.character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
    if rootPart then
        return rootPart.CFrame.LookVector
    end
    
    return Vector3.new(0, 0, -1) -- Default forward
end

-- Check if position is within field of view
function VisionSystem:IsInFOV(targetPosition)
    local eyePosition = self:GetEyePosition()
    if not eyePosition then return false end
    
    local lookDirection = self:GetLookDirection()
    local directionToTarget = (targetPosition - eyePosition).Unit
    
    -- Calculate angle between look direction and target direction
    local dotProduct = lookDirection:Dot(directionToTarget)
    local angle = math.deg(math.acos(dotProduct))
    
    -- Check if within FOV
    return angle <= (self.fov / 2)
end

-- Raycast to check line of sight
function VisionSystem:HasLineOfSight(targetPosition)
    local eyePosition = self:GetEyePosition()
    if not eyePosition then return false end
    
    self:UpdateRaycastFilter()
    
    local direction = targetPosition - eyePosition
    local distance = direction.Magnitude
    
    if distance > self.visionRange then
        return false
    end
    
    -- Perform raycast
    local raycastResult = self.workspace:Raycast(eyePosition, direction, self.raycastParams)
    
    -- If no hit, clear line of sight
    if not raycastResult then
        return true
    end
    
    -- Check if we hit the target or something in front of it
    local hitDistance = (raycastResult.Position - eyePosition).Magnitude
    return hitDistance >= (distance - 1) -- Small tolerance
end

-- Check if can see target (FOV + LOS)
function VisionSystem:CanSeePosition(targetPosition)
    if not self:IsInFOV(targetPosition) then
        return false
    end
    
    return self:HasLineOfSight(targetPosition)
end

-- Check if can see a player
function VisionSystem:CanSeePlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        return false
    end
    
    local targetRoot = targetPlayer.Character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
    if not targetRoot then
        return false
    end
    
    return self:CanSeePosition(targetRoot.Position)
end

-- Check if can see an object
function VisionSystem:CanSeeObject(targetObject, objectType)
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
    
    return self:CanSeePosition(targetPosition)
end

-- Get distance to target position
function VisionSystem:GetDistanceTo(targetPosition)
    local eyePosition = self:GetEyePosition()
    if not eyePosition then return math.huge end
    
    return (targetPosition - eyePosition).Magnitude
end

-- Get distance to player
function VisionSystem:GetDistanceToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        return math.huge
    end
    
    local targetRoot = targetPlayer.Character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
    if not targetRoot then
        return math.huge
    end
    
    return self:GetDistanceTo(targetRoot.Position)
end

-- Scan for visible players (returns list of players in vision)
function VisionSystem:ScanForPlayers(playerList)
    local visiblePlayers = {}
    
    for _, player in ipairs(playerList) do
        if self:CanSeePlayer(player) then
            local distance = self:GetDistanceToPlayer(player)
            table.insert(visiblePlayers, {
                Player = player,
                Distance = distance,
                Character = player.Character
            })
        end
    end
    
    -- Sort by distance (nearest first)
    table.sort(visiblePlayers, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return visiblePlayers
end

-- Scan for visible objects in a list
function VisionSystem:ScanForObjects(objectList, objectType)
    local visibleObjects = {}
    
    for _, obj in ipairs(objectList) do
        if self:CanSeeObject(obj, objectType) then
            local objPosition = nil
            
            if obj:IsA("BasePart") then
                objPosition = obj.Position
            elseif obj:IsA("Model") then
                local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if primaryPart then
                    objPosition = primaryPart.Position
                end
            end
            
            if objPosition then
                local distance = self:GetDistanceTo(objPosition)
                table.insert(visibleObjects, {
                    Object = obj,
                    Distance = distance,
                    Position = objPosition
                })
            end
        end
    end
    
    -- Sort by distance (nearest first)
    table.sort(visibleObjects, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return visibleObjects
end

-- Predict target position based on velocity (for aiming)
function VisionSystem:PredictTargetPosition(targetPlayer, predictionTime)
    if not targetPlayer or not targetPlayer.Character then
        return nil
    end
    
    local targetRoot = targetPlayer.Character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
    if not targetRoot then
        return nil
    end
    
    -- Get current position and velocity
    local currentPosition = targetRoot.Position
    local velocity = targetRoot.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
    
    -- Predict future position
    predictionTime = predictionTime or 0.1 -- Default 100ms ahead
    local predictedPosition = currentPosition + (velocity * predictionTime)
    
    return predictedPosition
end

-- Check if position is within range
function VisionSystem:IsInRange(targetPosition, range)
    local distance = self:GetDistanceTo(targetPosition)
    return distance <= range
end

-- Get all positions within vision cone (for debugging)
function VisionSystem:GetVisionCone()
    local eyePosition = self:GetEyePosition()
    if not eyePosition then return {} end
    
    local lookDirection = self:GetLookDirection()
    local rightVector = lookDirection:Cross(Vector3.new(0, 1, 0)).Unit
    
    -- Calculate cone points
    local halfFOV = math.rad(self.fov / 2)
    local leftBound = CFrame.Angles(0, halfFOV, 0) * lookDirection
    local rightBound = CFrame.Angles(0, -halfFOV, 0) * lookDirection
    
    return {
        Origin = eyePosition,
        Forward = eyePosition + (lookDirection * self.visionRange),
        Left = eyePosition + (leftBound * self.visionRange),
        Right = eyePosition + (rightBound * self.visionRange)
    }
end

return VisionSystem
