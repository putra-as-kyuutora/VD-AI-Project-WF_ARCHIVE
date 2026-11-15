-- ============================================
-- SensorSystem.lua
-- Detects nearby objects, players, and environmental elements
-- ============================================

local SensorSystem = {}
SensorSystem.__index = SensorSystem

-- Constructor
function SensorSystem.new(character, aiConfig, gameConfig, objectDetector, teamManager)
    local self = setmetatable({}, SensorSystem)
    
    self.character = character
    self.aiConfig = aiConfig
    self.gameConfig = gameConfig
    self.objectDetector = objectDetector
    self.teamManager = teamManager
    
    -- Sensor parameters
    self.scanRange = aiConfig.Sensor.ScanRange
    self.scanRate = aiConfig.Sensor.ScanRate
    self.priorityRadius = aiConfig.Sensor.PriorityRadius
    self.lastScan = 0
    
    -- Sensor data cache
    self.sensorData = {
        NearbyEnemies = {},
        NearbyAllies = {},
        NearbyGenerators = {},
        NearbyWindows = {},
        NearbyPallets = {},
        NearbyHooks = {},
        NearbyGates = {},
        ClosestEnemy = nil,
        ClosestAlly = nil,
        ClosestGenerator = nil,
        InDanger = false
    }
    
    return self
end

-- Get character position
function SensorSystem:GetPosition()
    if not self.character then return nil end
    
    local rootPart = self.character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
    if rootPart then
        return rootPart.Position
    end
    
    return nil
end

-- Scan for nearby players (enemies and allies)
function SensorSystem:ScanPlayers()
    local myPosition = self:GetPosition()
    if not myPosition then return end
    
    local players = self.gameConfig.Services.Players:GetPlayers()
    local nearbyEnemies = {}
    local nearbyAllies = {}
    local closestEnemy = nil
    local closestEnemyDistance = math.huge
    local closestAlly = nil
    local closestAllyDistance = math.huge
    
    for _, player in ipairs(players) do
        if player ~= self.gameConfig.Services.Players.LocalPlayer then
            if player.Character and self.teamManager:IsValidTarget(player) then
                local targetRoot = player.Character:FindFirstChild(self.gameConfig.CharacterParts.ROOT)
                if targetRoot then
                    local distance = (targetRoot.Position - myPosition).Magnitude
                    
                    if distance <= self.scanRange then
                        local playerData = {
                            Player = player,
                            Character = player.Character,
                            Position = targetRoot.Position,
                            Distance = distance,
                            IsPriority = distance <= self.priorityRadius
                        }
                        
                        -- Check if enemy or ally
                        if self.teamManager:IsEnemy(player) then
                            table.insert(nearbyEnemies, playerData)
                            
                            if distance < closestEnemyDistance then
                                closestEnemyDistance = distance
                                closestEnemy = playerData
                            end
                        elseif self.teamManager:IsAlly(player) then
                            table.insert(nearbyAllies, playerData)
                            
                            if distance < closestAllyDistance then
                                closestAllyDistance = distance
                                closestAlly = playerData
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(nearbyEnemies, function(a, b) return a.Distance < b.Distance end)
    table.sort(nearbyAllies, function(a, b) return a.Distance < b.Distance end)
    
    self.sensorData.NearbyEnemies = nearbyEnemies
    self.sensorData.NearbyAllies = nearbyAllies
    self.sensorData.ClosestEnemy = closestEnemy
    self.sensorData.ClosestAlly = closestAlly
    
    -- Determine if in danger (enemy very close)
    if closestEnemy and closestEnemyDistance <= 20 then
        self.sensorData.InDanger = true
    else
        self.sensorData.InDanger = false
    end
end

-- Scan for nearby map objects
function SensorSystem:ScanObjects()
    local myPosition = self:GetPosition()
    if not myPosition then return end
    
    -- Get all objects in radius
    local nearbyObjects = self.objectDetector:GetObjectsInRadius("All", myPosition, self.scanRange)
    
    -- Separate by type
    local generators = {}
    local windows = {}
    local pallets = {}
    local hooks = {}
    local gates = {}
    
    for _, objData in ipairs(nearbyObjects) do
        objData.IsPriority = objData.Distance <= self.priorityRadius
        
        if objData.Type == "Generator" then
            -- Add generator progress info
            objData.Progress = self.objectDetector:GetGeneratorProgress(objData.Object)
            objData.IsComplete = self.objectDetector:IsGeneratorComplete(objData.Object)
            table.insert(generators, objData)
        elseif objData.Type == "Window" then
            table.insert(windows, objData)
        elseif objData.Type == "Pallet" then
            table.insert(pallets, objData)
        elseif objData.Type == "Hook" then
            table.insert(hooks, objData)
        elseif objData.Type == "Gate" then
            table.insert(gates, objData)
        end
    end
    
    self.sensorData.NearbyGenerators = generators
    self.sensorData.NearbyWindows = windows
    self.sensorData.NearbyPallets = pallets
    self.sensorData.NearbyHooks = hooks
    self.sensorData.NearbyGates = gates
    
    -- Find closest generator
    if #generators > 0 then
        self.sensorData.ClosestGenerator = generators[1]
    else
        self.sensorData.ClosestGenerator = nil
    end
end

-- Main scan function (scans everything)
function SensorSystem:Scan()
    local currentTime = tick()
    
    -- Rate limiting
    if currentTime - self.lastScan < self.scanRate then
        return
    end
    
    self.lastScan = currentTime
    
    -- Scan players and objects
    self:ScanPlayers()
    self:ScanObjects()
end

-- Get sensor data
function SensorSystem:GetData()
    return self.sensorData
end

-- Get nearby enemies
function SensorSystem:GetNearbyEnemies()
    return self.sensorData.NearbyEnemies
end

-- Get nearby allies
function SensorSystem:GetNearbyAllies()
    return self.sensorData.NearbyAllies
end

-- Get closest enemy
function SensorSystem:GetClosestEnemy()
    return self.sensorData.ClosestEnemy
end

-- Get closest ally
function SensorSystem:GetClosestAlly()
    return self.sensorData.ClosestAlly
end

-- Check if in danger
function SensorSystem:IsInDanger()
    return self.sensorData.InDanger
end

-- Get incomplete generators (for survivor AI)
function SensorSystem:GetIncompleteGenerators()
    local incompleteGens = {}
    
    for _, genData in ipairs(self.sensorData.NearbyGenerators) do
        if not genData.IsComplete then
            table.insert(incompleteGens, genData)
        end
    end
    
    return incompleteGens
end

-- Get nearest incomplete generator
function SensorSystem:GetNearestIncompleteGenerator()
    local incompleteGens = self:GetIncompleteGenerators()
    
    if #incompleteGens > 0 then
        return incompleteGens[1] -- Already sorted by distance
    end
    
    return nil
end

-- Get generators sorted by priority (lowest progress first)
function SensorSystem:GetGeneratorsByPriority()
    local generators = {}
    
    for _, genData in ipairs(self.sensorData.NearbyGenerators) do
        if not genData.IsComplete then
            table.insert(generators, genData)
        end
    end
    
    -- Sort by progress (lowest first)
    table.sort(generators, function(a, b)
        return a.Progress < b.Progress
    end)
    
    return generators
end

-- Get nearest escape object (window or pallet)
function SensorSystem:GetNearestEscapeObject()
    local escapeObjects = {}
    
    -- Combine windows and pallets
    for _, winData in ipairs(self.sensorData.NearbyWindows) do
        table.insert(escapeObjects, winData)
    end
    for _, palletData in ipairs(self.sensorData.NearbyPallets) do
        table.insert(escapeObjects, palletData)
    end
    
    -- Sort by distance
    table.sort(escapeObjects, function(a, b)
        return a.Distance < b.Distance
    end)
    
    if #escapeObjects > 0 then
        return escapeObjects[1]
    end
    
    return nil
end

-- Get all nearby objects of a specific type
function SensorSystem:GetObjectsByType(objectType)
    if objectType == "Generator" then
        return self.sensorData.NearbyGenerators
    elseif objectType == "Window" then
        return self.sensorData.NearbyWindows
    elseif objectType == "Pallet" then
        return self.sensorData.NearbyPallets
    elseif objectType == "Hook" then
        return self.sensorData.NearbyHooks
    elseif objectType == "Gate" then
        return self.sensorData.NearbyGates
    end
    
    return {}
end

-- Check if allies need help (low health, hooked, etc.)
function SensorSystem:GetAlliesNeedingHelp()
    local alliesNeedingHelp = {}
    
    for _, allyData in ipairs(self.sensorData.NearbyAllies) do
        local humanoid = allyData.Character:FindFirstChild(self.gameConfig.CharacterParts.HUMANOID)
        if humanoid then
            local healthPercent = (humanoid.Health / humanoid.MaxHealth) * 100
            
            -- Check if ally needs help
            if healthPercent < 50 then
                allyData.HelpType = "Heal"
                allyData.Priority = 100 - healthPercent -- Lower health = higher priority
                table.insert(alliesNeedingHelp, allyData)
            end
            
            -- TODO: Check if ally is hooked (would need more game-specific logic)
        end
    end
    
    -- Sort by priority
    table.sort(alliesNeedingHelp, function(a, b)
        return a.Priority > b.Priority
    end)
    
    return alliesNeedingHelp
end

-- Force immediate scan (skip rate limit)
function SensorSystem:ForceScan()
    self.lastScan = 0
    self:Scan()
end

return SensorSystem
