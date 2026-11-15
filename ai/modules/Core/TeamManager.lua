-- ============================================
-- TeamManager.lua
-- Handles team detection and ally/enemy identification
-- ============================================

local TeamManager = {}
TeamManager.__index = TeamManager

-- Constructor
function TeamManager.new(player, gameConfig)
    local self = setmetatable({}, TeamManager)
    
    self.player = player
    self.config = gameConfig
    self.myTeam = nil
    self.lastTeamCheck = 0
    self.teamCheckInterval = 1 -- Check team every 1 second
    
    -- Initialize team
    self:UpdateTeam()
    
    return self
end

-- Update current team (in case it changes during game)
function TeamManager:UpdateTeam()
    if self.player and self.player.Team then
        self.myTeam = self.player.Team.Name
        self.lastTeamCheck = tick()
        return true
    end
    return false
end

-- Get bot's current team
function TeamManager:GetMyTeam()
    local currentTime = tick()
    if currentTime - self.lastTeamCheck >= self.teamCheckInterval then
        self:UpdateTeam()
    end
    return self.myTeam
end

-- Get a player's team
function TeamManager:GetPlayerTeam(targetPlayer)
    if not targetPlayer then return nil end
    
    if targetPlayer.Team then
        return targetPlayer.Team.Name
    end
    return nil
end

-- Check if target player is on the same team
function TeamManager:IsAlly(targetPlayer)
    if not targetPlayer then return false end
    
    local myTeam = self:GetMyTeam()
    local targetTeam = self:GetPlayerTeam(targetPlayer)
    
    if not myTeam or not targetTeam then return false end
    
    -- Spectators are not allies to anyone
    if myTeam == self.config.Teams.SPECTATOR or targetTeam == self.config.Teams.SPECTATOR then
        return false
    end
    
    return myTeam == targetTeam
end

-- Check if target player is an enemy
function TeamManager:IsEnemy(targetPlayer)
    if not targetPlayer then return false end
    
    local myTeam = self:GetMyTeam()
    local targetTeam = self:GetPlayerTeam(targetPlayer)
    
    if not myTeam or not targetTeam then return false end
    
    -- Spectators are not enemies
    if targetTeam == self.config.Teams.SPECTATOR then
        return false
    end
    
    -- If we're spectator, no one is enemy
    if myTeam == self.config.Teams.SPECTATOR then
        return false
    end
    
    return myTeam ~= targetTeam
end

-- Check if bot is Killer
function TeamManager:IsKiller()
    local myTeam = self:GetMyTeam()
    return myTeam == self.config.Teams.KILLER
end

-- Check if bot is Survivor
function TeamManager:IsSurvivor()
    local myTeam = self:GetMyTeam()
    return myTeam == self.config.Teams.SURVIVORS
end

-- Check if bot is Spectator
function TeamManager:IsSpectator()
    local myTeam = self:GetMyTeam()
    return myTeam == self.config.Teams.SPECTATOR
end

-- Get all enemies in player list
function TeamManager:GetAllEnemies()
    local enemies = {}
    local players = self.config.Services.Players:GetPlayers()
    
    for _, player in ipairs(players) do
        if player ~= self.player and self:IsEnemy(player) then
            table.insert(enemies, player)
        end
    end
    
    return enemies
end

-- Get all allies in player list
function TeamManager:GetAllAllies()
    local allies = {}
    local players = self.config.Services.Players:GetPlayers()
    
    for _, player in ipairs(players) do
        if player ~= self.player and self:IsAlly(player) then
            table.insert(allies, player)
        end
    end
    
    return allies
end

-- Get team color (for debugging/ESP)
function TeamManager:GetTeamColor(teamName)
    if teamName == self.config.Teams.KILLER then
        return Color3.fromRGB(255, 93, 108) -- Red
    elseif teamName == self.config.Teams.SURVIVORS then
        return Color3.fromRGB(64, 224, 255) -- Blue
    else
        return Color3.fromRGB(128, 128, 128) -- Gray for spectator
    end
end

-- Check if target player is valid (has character and not spectator)
function TeamManager:IsValidTarget(targetPlayer)
    if not targetPlayer then return false end
    if not targetPlayer.Character then return false end
    
    local humanoid = targetPlayer.Character:FindFirstChild(self.config.CharacterParts.HUMANOID)
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local targetTeam = self:GetPlayerTeam(targetPlayer)
    if targetTeam == self.config.Teams.SPECTATOR then return false end
    
    return true
end

return TeamManager
