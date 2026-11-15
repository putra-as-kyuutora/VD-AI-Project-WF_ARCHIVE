-- ============================================
-- ObjectDetector.lua
-- Universal object detection system for all game objects
-- ============================================

local ObjectDetector = {}
ObjectDetector.__index = ObjectDetector

-- Constructor
function ObjectDetector.new(gameConfig)
    local self = setmetatable({}, ObjectDetector)
    
    self.config = gameConfig
    self.workspace = gameConfig.Services.Workspace
    self.map = gameConfig.Map.Location
    
    -- Cache for detected objects (to avoid redundant searches)
    self.objectCache = {
        Generators = {},
        Windows = {},
        Pallets = {},
        Hooks = {},
        Gates = {},
        LastUpdate = 0,
        UpdateInterval = 2 -- Cache for 2 seconds
    }
    
    return self
end

-- Clear cache
function ObjectDetector:ClearCache()
    self.objectCache.Generators = {}
    self.objectCache.Windows = {}
    self.objectCache.Pallets = {}
    self.objectCache.Hooks = {}
    self.objectCache.Gates = {}
    self.objectCache.LastUpdate = 0
end

-- Scan for all map objects and cache them
function ObjectDetector:ScanMapObjects()
    local currentTime = tick()
    
    -- Use cache if still valid
    if currentTime - self.objectCache.LastUpdate < self.objectCache.UpdateInterval then
        return
    end
    
    -- Clear old cache
    self:ClearCache()
    
    if not self.map then
        warn("[ObjectDetector] Map not found!")
        return
    end
    
    -- Scan all descendants in map
    for _, obj in ipairs(self.map:GetDescendants()) do
        -- Generators
        if obj.Name == self.config.Objects.Generator.Name then
            table.insert(self.objectCache.Generators, obj)
        
        -- Windows
        elseif obj.Name == self.config.Objects.Window.Name then
            table.insert(self.objectCache.Windows, obj)
        
        -- Pallets (multiple possible names)
        elseif table.find(self.config.Objects.Pallet.Names, obj.Name) then
            table.insert(self.objectCache.Pallets, obj)
        
        -- Hooks
        elseif obj.Name == self.config.Objects.Hook.Name then
            table.insert(self.objectCache.Hooks, obj)
        
        -- Gates
        elseif obj.Name == self.config.Objects.Gate.Name then
            table.insert(self.objectCache.Gates, obj)
        end
    end
    
    self.objectCache.LastUpdate = currentTime
end

-- Get all generators
function ObjectDetector:GetGenerators()
    self:ScanMapObjects()
    return self.objectCache.Generators
end

-- Get all windows
function ObjectDetector:GetWindows()
    self:ScanMapObjects()
    return self.objectCache.Windows
end

-- Get all pallets
function ObjectDetector:GetPallets()
    self:ScanMapObjects()
    return self.objectCache.Pallets
end

-- Get all hooks
function ObjectDetector:GetHooks()
    self:ScanMapObjects()
    return self.objectCache.Hooks
end

-- Get all gates
function ObjectDetector:GetGates()
    self:ScanMapObjects()
    return self.objectCache.Gates
end

-- Find nearest object of a type from a position
function ObjectDetector:FindNearest(objectType, fromPosition)
    local objects = {}
    
    if objectType == "Generator" then
        objects = self:GetGenerators()
    elseif objectType == "Window" then
        objects = self:GetWindows()
    elseif objectType == "Pallet" then
        objects = self:GetPallets()
    elseif objectType == "Hook" then
        objects = self:GetHooks()
    elseif objectType == "Gate" then
        objects = self:GetGates()
    else
        warn("[ObjectDetector] Unknown object type: " .. tostring(objectType))
        return nil, math.huge
    end
    
    local nearestObject = nil
    local nearestDistance = math.huge
    
    for _, obj in ipairs(objects) do
        local objPosition = self:GetObjectPosition(obj, objectType)
        if objPosition then
            local distance = (objPosition - fromPosition).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestObject = obj
            end
        end
    end
    
    return nearestObject, nearestDistance
end

-- Get position of an object (based on its detection part)
function ObjectDetector:GetObjectPosition(obj, objectType)
    if not obj then return nil end
    
    local detectionPart = nil
    
    if objectType == "Generator" then
        detectionPart = obj:FindFirstChild(self.config.Objects.Generator.DetectionPart)
    elseif objectType == "Window" then
        detectionPart = obj:FindFirstChild(self.config.Objects.Window.DetectionPart)
    elseif objectType == "Pallet" then
        detectionPart = obj:FindFirstChild(self.config.Objects.Pallet.DetectionPart)
    elseif objectType == "Hook" then
        detectionPart = obj:FindFirstChild(self.config.Objects.Hook.DetectionPart)
    elseif objectType == "Gate" then
        detectionPart = obj:FindFirstChild(self.config.Objects.Gate.DetectionPart)
    end
    
    if detectionPart and detectionPart:IsA("BasePart") then
        return detectionPart.Position
    elseif detectionPart and detectionPart:IsA("Model") then
        local primaryPart = detectionPart.PrimaryPart or detectionPart:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            return primaryPart.Position
        end
    end
    
    -- Fallback: try to get position from object itself
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            return primaryPart.Position
        end
    end
    
    return nil
end

-- Get objects within a radius
function ObjectDetector:GetObjectsInRadius(objectType, fromPosition, radius)
    local objects = {}
    
    if objectType == "Generator" then
        objects = self:GetGenerators()
    elseif objectType == "Window" then
        objects = self:GetWindows()
    elseif objectType == "Pallet" then
        objects = self:GetPallets()
    elseif objectType == "Hook" then
        objects = self:GetHooks()
    elseif objectType == "Gate" then
        objects = self:GetGates()
    elseif objectType == "All" then
        -- Get all types
        for _, gen in ipairs(self:GetGenerators()) do table.insert(objects, {Object = gen, Type = "Generator"}) end
        for _, win in ipairs(self:GetWindows()) do table.insert(objects, {Object = win, Type = "Window"}) end
        for _, pal in ipairs(self:GetPallets()) do table.insert(objects, {Object = pal, Type = "Pallet"}) end
        for _, hook in ipairs(self:GetHooks()) do table.insert(objects, {Object = hook, Type = "Hook"}) end
        for _, gate in ipairs(self:GetGates()) do table.insert(objects, {Object = gate, Type = "Gate"}) end
    end
    
    local objectsInRadius = {}
    
    for _, obj in ipairs(objects) do
        local objData = obj
        local objInstance = obj
        local objType = objectType
        
        -- Handle "All" type
        if objectType == "All" then
            objInstance = obj.Object
            objType = obj.Type
        end
        
        local objPosition = self:GetObjectPosition(objInstance, objType)
        if objPosition then
            local distance = (objPosition - fromPosition).Magnitude
            if distance <= radius then
                table.insert(objectsInRadius, {
                    Object = objInstance,
                    Type = objType,
                    Position = objPosition,
                    Distance = distance
                })
            end
        end
    end
    
    -- Sort by distance
    table.sort(objectsInRadius, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return objectsInRadius
end

-- Get generator repair progress
function ObjectDetector:GetGeneratorProgress(generator)
    if not generator then return 0 end
    return generator:GetAttribute("RepairProgress") or 0
end

-- Check if generator is fully repaired
function ObjectDetector:IsGeneratorComplete(generator)
    return self:GetGeneratorProgress(generator) >= 100
end

-- Identify what type of object something is
function ObjectDetector:IdentifyObject(obj)
    if not obj then return "Unknown" end
    
    local name = obj.Name
    
    if name == self.config.Objects.Generator.Name then
        return "Generator"
    elseif name == self.config.Objects.Window.Name then
        return "Window"
    elseif table.find(self.config.Objects.Pallet.Names, name) then
        return "Pallet"
    elseif name == self.config.Objects.Hook.Name then
        return "Hook"
    elseif name == self.config.Objects.Gate.Name then
        return "Gate"
    end
    
    return "Unknown"
end

-- Check if round is active (map has Antifling)
function ObjectDetector:IsRoundActive()
    if not self.map then return false end
    return self.map:FindFirstChild(self.config.Map.AntiflingingCheck) ~= nil
end

return ObjectDetector
