--[[
    ════════════════════════════════════════════════════════
    WF Remote Spy Tool v1.0
    By: WolfFamily Private Tools
    
    Fungsi:
    - Hook semua RemoteEvent:FireServer dan RemoteFunction:InvokeServer
    - Cetak path, nama, dan argumen lengkap ke Output
    - Filter whitelist/blacklist nama remote agar tidak spam
    - Auto-stop setelah X detik (opsional)
    
    Cara Pakai:
    1. Inject script ini
    2. Lakukan aksi di game yang ingin kamu spy (contoh: jatuhkan palet)
    3. Lihat output/console untuk melihat remote + argumen yang dipakai
    4. Setelah dapat, gunakan info tsb untuk fix script utama
    
    Delta Compatible: getrawmetatable, setreadonly, newcclosure ✓
    ════════════════════════════════════════════════════════
]]

-- ─────────────────────────────────────────────────────────
--  CONFIG
-- ─────────────────────────────────────────────────────────

local CONFIG = {
    -- Whitelist: hanya tampilkan remote yang MENGANDUNG kata ini
    -- Kosongkan {} untuk tampilkan SEMUA remote
    Whitelist = {},

    -- Blacklist: sembunyikan remote yang mengandung kata ini (untuk kurangi spam)
    Blacklist = {
        "Heartbeat", "Step", "RenderStep", "Physics",
        "Mouse", "Camera", "Input", "Animate",
        "Chat", "AvatarEditor", "FriendService",
    },

    -- Tampilkan argumen secara detail
    ShowArgs = true,

    -- Print ke Output atau ke gui notif
    PrintToOutput = true,

    -- Auto stop setelah N detik (0 = tidak auto stop)
    AutoStopSeconds = 0,

    -- Tambahkan timestamp di setiap log
    ShowTimestamp = true,

    -- Hanya log remote yang belum pernah dilihat sebelumnya (mode unique only)
    UniqueOnly = false,
}

-- ─────────────────────────────────────────────────────────
--  INTERNAL STATE
-- ─────────────────────────────────────────────────────────

local loggedRemotes = {} -- untuk UniqueOnly
local isActive = true
local hookCount = 0
local startTime = tick()

-- ─────────────────────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────────────────────

local function getTimestamp()
    local t = tick() - startTime
    return string.format("[%.2fs]", t)
end

local function shouldLog(path)
    -- Check Blacklist
    for _, keyword in ipairs(CONFIG.Blacklist) do
        if path:lower():find(keyword:lower()) then
            return false
        end
    end

    -- Check Whitelist (jika ada isi)
    if #CONFIG.Whitelist > 0 then
        for _, keyword in ipairs(CONFIG.Whitelist) do
            if path:lower():find(keyword:lower()) then
                return true
            end
        end
        return false -- Tidak ada yg match whitelist
    end

    return true
end

local function formatArg(arg, index)
    local t = typeof(arg)
    local val = ""

    if t == "string" then
        val = '"' .. arg .. '"'
    elseif t == "number" then
        val = tostring(arg)
    elseif t == "boolean" then
        val = tostring(arg)
    elseif t == "Instance" then
        local ok, path = pcall(function() return arg:GetFullName() end)
        val = ok and path or tostring(arg)
        val = val .. " [" .. arg.ClassName .. "]"
    elseif t == "Vector3" then
        val = string.format("Vector3(%.2f, %.2f, %.2f)", arg.X, arg.Y, arg.Z)
    elseif t == "CFrame" then
        val = string.format("CFrame(%.2f, %.2f, %.2f)", arg.X, arg.Y, arg.Z)
    elseif t == "Color3" then
        val = string.format("Color3(%.2f, %.2f, %.2f)", arg.R, arg.G, arg.B)
    elseif t == "table" then
        val = "{table, #keys=" .. tostring(#arg) .. "}"
    elseif t == "nil" then
        val = "nil"
    else
        val = tostring(arg)
    end

    return string.format("    [%d] %s = %s", index, t, val)
end

local function doLog(method, path, args)
    if not isActive then return end
    if not shouldLog(path) then return end

    if CONFIG.UniqueOnly then
        local key = method .. "|" .. path
        if loggedRemotes[key] then return end
        loggedRemotes[key] = true
    end

    hookCount = hookCount + 1

    local ts = CONFIG.ShowTimestamp and (getTimestamp() .. " ") or ""
    local header = string.format("%s[#%d] %s → %s", ts, hookCount, method, path)

    print(header)

    if CONFIG.ShowArgs and #args > 0 then
        for i, arg in ipairs(args) do
            print(formatArg(arg, i))
        end
    elseif CONFIG.ShowArgs then
        print("    (no args)")
    end

    print("") -- empty line separator
end

-- ─────────────────────────────────────────────────────────
--  HOOK
-- ─────────────────────────────────────────────────────────

local mt = getrawmetatable(game)
setreadonly(mt, false)

local originalNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if isActive and (method == "FireServer" or method == "InvokeServer") then
        local ok, path = pcall(function() return self:GetFullName() end)
        if ok then
            local args = {...}
            doLog(method, path, args)
        end
    end

    return originalNamecall(self, ...)
end)

setreadonly(mt, true)

-- ─────────────────────────────────────────────────────────
--  AUTO STOP (Opsional)
-- ─────────────────────────────────────────────────────────

if CONFIG.AutoStopSeconds > 0 then
    task.delay(CONFIG.AutoStopSeconds, function()
        isActive = false
        setreadonly(mt, false)
        mt.__namecall = originalNamecall
        setreadonly(mt, true)
        print(string.format("[WF Remote Spy] Auto-stopped setelah %ds. Total: %d remotes logged.", CONFIG.AutoStopSeconds, hookCount))
    end)
end

-- ─────────────────────────────────────────────────────────
--  MANUAL STOP FUNCTION
-- ─────────────────────────────────────────────────────────

--[[
    Untuk stop manual, jalankan di executor:

    WF_RemoteSpy_Stop()
]]

WF_RemoteSpy_Stop = function()
    isActive = false
    setreadonly(mt, false)
    mt.__namecall = originalNamecall
    setreadonly(mt, true)
    print(string.format("[WF Remote Spy] Stopped. Total: %d remotes dicatat.", hookCount))
end

print("════════════════════════════════════════════")
print("[WF Remote Spy] AKTIF - Pantau Output/Console!")
print("  > Lakukan aksi di game (misal: jatuhkan palet)")
print("  > Remote + argumen akan muncul di sini")
print("  > Untuk stop: jalankan WF_RemoteSpy_Stop()")
print("════════════════════════════════════════════")
