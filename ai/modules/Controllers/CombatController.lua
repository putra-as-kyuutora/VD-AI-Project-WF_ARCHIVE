-- ============================================
-- CombatController.lua
-- Handles combat actions, attacking, and combat state
-- ============================================

local CombatController = {}
CombatController.__index = CombatController

-- Constructor
function CombatController.new(character, aiConfig, gameConfig, visionSystem)
    local self = setmetatable({}, CombatController)
    
    self.character = character
    self.aiConfig = aiConfig
    self.gameConfig = gameConfig
    self.visionSystem = visionSystem
    self.userInputService = gameConfig.Services.UserInputService
    
    -- Combat state
    self.currentTarget = nil
    self.isAttacking = false
    self.lastAttackTime = 0
    self.attackCooldown = aiConfig.Combat.AttackCooldown
    self.attackRange = aiConfig.Combat.AttackRange
    self.shootRange = aiConfig.Combat.ShootRange
    
    -- Combat mode
    self.combatMode = "Melee" -- "Melee" or "Ranged"
    
    return self
end

-- Get humanoid from character
function CombatController:GetHumanoid()
    if not self.character then return nil end
    return self.character:FindFirstChild(self.gameConfig.CharacterParts.HUMANOID)
end

-- Get root part from character
function CombatController:GetRootPart()
    if not self.character then return nil end
    return self.character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
end

-- Get current position
function CombatController:GetPosition()
    local rootPart = self:GetRootPart()
    if rootPart then
        return rootPart.Position
    end
    return nil
end

-- Set current target
function CombatController:SetTarget(target)
    self.currentTarget = target
end

-- Get current target
function CombatController:GetTarget()
    return self.currentTarget
end

-- Clear target
function CombatController:ClearTarget()
    self.currentTarget = nil
    self.isAttacking = false
end

-- Check if can attack (cooldown check)
function CombatController:CanAttack()
    local currentTime = tick()
    return (currentTime - self.lastAttackTime) >= self.attackCooldown
end

-- Check if target is in attack range
function CombatController:IsTargetInRange(target)
    if not target then return false end
    
    local targetPosition = nil
    
    -- Handle player target
    if typeof(target) == "Instance" and target:IsA("Player") then
        if target.Character then
            local targetRoot = target.Character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
            if targetRoot then
                targetPosition = targetRoot.Position
            end
        end
    -- Handle character target
    elseif typeof(target) == "Instance" and target:IsA("Model") then
        local targetRoot = target:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
        if targetRoot then
            targetPosition = targetRoot.Position
        end
    -- Handle position
    elseif typeof(target) == "Vector3" then
        targetPosition = target
    end
    
    if not targetPosition then return false end
    
    local distance = self.visionSystem:GetDistanceTo(targetPosition)
    local range = self.combatMode == "Ranged" and self.shootRange or self.attackRange
    
    return distance <= range
end

-- Face towards target
function CombatController:FaceTarget(target)
    local rootPart = self:GetRootPart()
    if not rootPart then return false end
    
    local targetPosition = nil
    
    -- Handle player target
    if typeof(target) == "Instance" and target:IsA("Player") then
        if target.Character then
            local targetRoot = target.Character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
            if targetRoot then
                targetPosition = targetRoot.Position
            end
        end
    -- Handle character target
    elseif typeof(target) == "Instance" and target:IsA("Model") then
        local targetRoot = target:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
        if targetRoot then
            targetPosition = targetRoot.Position
        end
    -- Handle position
    elseif typeof(target) == "Vector3" then
        targetPosition = target
    end
    
    if not targetPosition then return false end
    
    -- Calculate look direction (ignore Y axis for rotation)
    local currentPosition = rootPart.Position
    local lookDirection = Vector3.new(
        targetPosition.X - currentPosition.X,
        0,
        targetPosition.Z - currentPosition.Z
    ).Unit
    
    -- Create new CFrame facing target
    local newCFrame = CFrame.new(currentPosition, currentPosition + lookDirection)
    rootPart.CFrame = newCFrame
    
    return true
end

-- Simulate attack input (basic implementation)
function CombatController:SimulateAttack()
    -- This is a placeholder - actual implementation depends on game's input system
    -- Options:
    -- 1. Fire RemoteEvent
    -- 2. Simulate mouse click
    -- 3. Use tool/weapon directly
    
    -- Simulate mouse button press (basic approach)
    local success = pcall(function()
        -- Fire InputBegan for attack
        local fakeInput = {
            UserInputType = Enum.UserInputType.MouseButton1,
            UserInputState = Enum.UserInputState.Begin
        }
        
        -- Note: This may not work in all games - adjust based on Violence District's input system
        for _, connection in pairs(getconnections(self.userInputService.InputBegan)) do
            connection:Fire(fakeInput, false)
        end
    end)
    
    if not success then
        warn("[CombatController] Failed to simulate attack input")
    end
    
    return success
end

-- Perform melee attack
function CombatController:MeleeAttack(target)
    if not self:CanAttack() then
        return false
    end
    
    if not self:IsTargetInRange(target) then
        return false
    end
    
    -- Face target
    self:FaceTarget(target)
    
    -- Simulate attack
    self:SimulateAttack()
    
    -- Update attack state
    self.lastAttackTime = tick()
    self.isAttacking = true
    
    return true
end

-- Perform ranged attack (shoot)
function CombatController:RangedAttack(target)
    if not self:CanAttack() then
        return false
    end
    
    if not self:IsTargetInRange(target) then
        return false
    end
    
    -- Use prediction if enabled
    local aimPosition = nil
    
    if self.aiConfig.Combat.AimPrediction and typeof(target) == "Instance" and target:IsA("Player") then
        aimPosition = self.visionSystem:PredictTargetPosition(target, 0.1)
    end
    
    if not aimPosition then
        -- Fallback to direct aim
        aimPosition = target
    end
    
    -- Face target
    self:FaceTarget(aimPosition)
    
    -- Simulate shoot
    self:SimulateAttack()
    
    -- Update attack state
    self.lastAttackTime = tick()
    self.isAttacking = true
    
    return true
end

-- Main attack function (auto-detects combat mode)
function CombatController:Attack(target)
    if self.combatMode == "Ranged" then
        return self:RangedAttack(target)
    else
        return self:MeleeAttack(target)
    end
end

-- Set combat mode
function CombatController:SetCombatMode(mode)
    if mode == "Melee" or mode == "Ranged" then
        self.combatMode = mode
        return true
    end
    return false
end

-- Get combat mode
function CombatController:GetCombatMode()
    return self.combatMode
end

-- Check if currently attacking
function CombatController:IsAttacking()
    return self.isAttacking
end

-- Get distance to current target
function CombatController:GetDistanceToTarget()
    if not self.currentTarget then return math.huge end
    
    local targetPosition = nil
    
    if typeof(self.currentTarget) == "Instance" and self.currentTarget:IsA("Player") then
        if self.currentTarget.Character then
            local targetRoot = self.currentTarget.Character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
            if targetRoot then
                targetPosition = targetRoot.Position
            end
        end
    elseif typeof(self.currentTarget) == "Instance" and self.currentTarget:IsA("Model") then
        local targetRoot = self.currentTarget:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
        if targetRoot then
            targetPosition = targetRoot.Position
        end
    end
    
    if not targetPosition then return math.huge end
    
    return self.visionSystem:GetDistanceTo(targetPosition)
end

-- Get combat status
function CombatController:GetStatus()
    return {
        HasTarget = self.currentTarget ~= nil,
        IsAttacking = self.isAttacking,
        CanAttack = self:CanAttack(),
        CombatMode = self.combatMode,
        DistanceToTarget = self:GetDistanceToTarget(),
        TargetInRange = self:IsTargetInRange(self.currentTarget)
    }
end

-- Reset combat state
function CombatController:Reset()
    self:ClearTarget()
    self.lastAttackTime = 0
end

return CombatController
