-- ============================================
-- Simple Game Scanner (Delta Compatible)
-- Ultra-simplified version - no fancy UI
-- ============================================

print("════════════════════════════════════════")
print("🔍 VIOLENCE DISTRICT - SIMPLE SCANNER")
print("════════════════════════════════════════")
print("")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ════════════════════════════════════════
-- 1. INPUT SYSTEM
-- ════════════════════════════════════════
print("📱 INPUT SYSTEM:")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
print("  Platform: " .. (isMobile and "MOBILE ✓" or "PC"))
print("  Keyboard: " .. tostring(UserInputService.KeyboardEnabled))
print("  Touch: " .. tostring(UserInputService.TouchEnabled))
print("")

-- ════════════════════════════════════════
-- 2. MOBILE BUTTONS
-- ════════════════════════════════════════
print("🎮 SCANNING MOBILE BUTTONS...")
local buttonCount = 0
local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)

if playerGui then
    for _, gui in pairs(playerGui:GetChildren()) do
        for _, obj in pairs(gui:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                buttonCount = buttonCount + 1
                local btnText = obj:IsA("TextButton") and obj.Text or "ImageButton"
                print(string.format("  [%d] %s: '%s' (Parent: %s)", 
                    buttonCount, obj.Name, btnText, obj.Parent.Name))
            end
        end
    end
end
print("  Total: " .. buttonCount .. " buttons")
print("")

-- ════════════════════════════════════════
-- 3. SKILLCHECK GUI
-- ════════════════════════════════════════
print("🎯 SKILLCHECK GUI:")
if playerGui then
    local skillGui = playerGui:FindFirstChild("SkillCheckPromptGui")
    if skillGui then
        print("  ✓ Found: SkillCheckPromptGui")
        local check = skillGui:FindFirstChild("Check")
        if check then
            print("    - Check")
            if check:FindFirstChild("Goal") then print("      - Goal") end
            if check:FindFirstChild("Line") then print("      - Line") end
        end
    else
        print("  ✗ SkillCheckPromptGui not found (might appear during generator repair)")
    end
end
print("")

-- ════════════════════════════════════════
-- 4. CHARACTER INFO
-- ════════════════════════════════════════
print("🧍 CHARACTER INFO:")
local character = LocalPlayer.Character
if character then
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        print("  WalkSpeed: " .. humanoid.WalkSpeed)
        print("  Health: " .. humanoid.Health .. "/" .. humanoid.MaxHealth)
    end
    
    -- Check known attributes
    local knownAttrs = {"speedboost", "IsHooked", "Carried", "Knocked"}
    print("  Attributes:")
    for _, attr in pairs(knownAttrs) do
        local val = character:GetAttribute(attr)
        if val ~= nil then
            print("    " .. attr .. " = " .. tostring(val))
        end
    end
else
    print("  ✗ Character not loaded yet")
end
print("")

-- ════════════════════════════════════════
-- 5. MAP OBJECTS
-- ════════════════════════════════════════
print("🗺️ MAP OBJECTS:")
local map = workspace:FindFirstChild("Map")
if map then
    local objects = {
        Generator = 0,
        Window = 0,
        Palletwrong = 0,
        PalletAlien = 0,
        Hook = 0,
        Gate = 0
    }
    
    for _, obj in pairs(map:GetDescendants()) do
        if objects[obj.Name] then
            objects[obj.Name] = objects[obj.Name] + 1
        end
    end
    
    for name, count in pairs(objects) do
        if count > 0 then
            print("  " .. name .. ": " .. count)
        end
    end
else
    print("  ✗ Map not found (join a round first)")
end
print("")

-- ════════════════════════════════════════
-- 6. REMOTES
-- ════════════════════════════════════════
print("📡 REMOTES:")
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
    local remoteCount = 0
    for _, remote in pairs(remotes:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            remoteCount = remoteCount + 1
            if remoteCount <= 10 then -- Show first 10
                print("  " .. remote.Name .. " (" .. remote.ClassName .. ")")
            end
        end
    end
    if remoteCount > 10 then
        print("  ... +" .. (remoteCount - 10) .. " more remotes")
    end
else
    print("  ✗ Remotes folder not found")
end
print("")

-- ════════════════════════════════════════
-- 7. TEAM INFO
-- ════════════════════════════════════════
print("👥 TEAM INFO:")
if LocalPlayer.Team then
    print("  Your Team: " .. LocalPlayer.Team.Name)
    
    local teammates = 0
    local enemies = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team then
            if player.Team == LocalPlayer.Team then
                teammates = teammates + 1
            else
                enemies = enemies + 1
            end
        end
    end
    print("  Teammates: " .. teammates)
    print("  Enemies: " .. enemies)
else
    print("  ✗ Not in a team yet")
end
print("")

print("════════════════════════════════════════")
print("✅ SCAN COMPLETE!")
print("════════════════════════════════════════")
print("")
print("💡 NEXT STEPS:")
print("  1. Copy output console ke chat")
print("  2. Atau screenshot dan kirim")
print("  3. Info ini akan dipakai untuk configure AI")
print("")
