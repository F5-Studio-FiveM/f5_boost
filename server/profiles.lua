local dbReady = false

local function GetIdentifier(source)
    local license2, license = nil, nil
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            if string.sub(id, 1, 9) == 'license2:' then
                license2 = id
            elseif string.sub(id, 1, 8) == 'license:' then
                license = id
            end
        end
    end
    return license2 or license
end

DB.ready(function()
    DB.execute([[
        CREATE TABLE IF NOT EXISTS `f5_boost_profiles` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(100) NOT NULL,
            `slot` TINYINT UNSIGNED NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `settings` LONGTEXT NOT NULL,
            `is_default` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY `uk_identifier_slot` (`identifier`, `slot`),
            INDEX `idx_identifier_default` (`identifier`, `is_default`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    dbReady = true
    print('^2[f5_boost] Profiles table ready^0')
end)

local maxProfiles = Config.MaxProfiles or 5

local SETTINGS_SCHEMA = {
    graphicsPreset  = 'string',
    performanceMode = 'string',
    shadowDistance   = 'number',
    objectQuality   = 'number',
    characterQuality= 'number',
    vehicleDistance  = 'number',
    toggleClearEvents       = 'boolean',
    toggleLightReflections  = 'boolean',
    toggleRainWind          = 'boolean',
    toggleBloodStains       = 'boolean',
    toggleFireEffects       = 'boolean',
    toggleScenarios         = 'boolean',
}

local function SanitizeSettings(raw)
    local clean = {}
    for k, expected in pairs(SETTINGS_SCHEMA) do
        if raw[k] ~= nil and type(raw[k]) == expected then
            if expected == 'number' then
                clean[k] = math.max(0, math.min(100, math.floor(raw[k])))
            else
                clean[k] = raw[k]
            end
        end
    end
    return clean
end

local function GetProfiles(identifier)
    return DB.query(
        'SELECT slot, name, is_default FROM f5_boost_profiles WHERE identifier = ? ORDER BY slot',
        {identifier}
    ) or {}
end

RegisterNetEvent('f5_boost:server:requestProfiles', function()
    local src = source
    if not dbReady then
        TriggerClientEvent('f5_boost:client:receiveProfiles', src, {})
        return
    end

    local identifier = GetIdentifier(src)
    if not identifier then
        TriggerClientEvent('f5_boost:client:receiveProfiles', src, {})
        return
    end

    TriggerClientEvent('f5_boost:client:receiveProfiles', src, GetProfiles(identifier))
end)

RegisterNetEvent('f5_boost:server:getDefaultProfile', function()
    local src = source
    if not dbReady then
        TriggerClientEvent('f5_boost:client:applyDefaultProfile', src, nil)
        return
    end

    local identifier = GetIdentifier(src)
    if not identifier then
        TriggerClientEvent('f5_boost:client:applyDefaultProfile', src, nil)
        return
    end

    local rows = DB.query(
        'SELECT settings FROM f5_boost_profiles WHERE identifier = ? AND is_default = 1 LIMIT 1',
        {identifier}
    )

    if rows and #rows > 0 and rows[1].settings then
        local ok, settings = pcall(json.decode, rows[1].settings)
        if ok and type(settings) == 'table' then
            TriggerClientEvent('f5_boost:client:applyDefaultProfile', src, settings)
            return
        end
    end

    TriggerClientEvent('f5_boost:client:applyDefaultProfile', src, nil)
end)

RegisterNetEvent('f5_boost:server:saveProfile', function(data)
    local src = source
    if not dbReady then return end

    local identifier = GetIdentifier(src)
    if not identifier then return end
    if not data or type(data.name) ~= 'string' or type(data.settings) ~= 'table' then return end

    local name = data.name:sub(1, 50)
    if #name == 0 then return end

    local existing = DB.query('SELECT slot FROM f5_boost_profiles WHERE identifier = ?', {identifier}) or {}
    local used = {}
    for _, row in ipairs(existing) do used[row.slot] = true end

    local nextSlot = nil
    for i = 1, maxProfiles do
        if not used[i] then nextSlot = i; break end
    end

    if not nextSlot then
        TriggerClientEvent('f5_boost:client:notify', src, Translate('notify_max_profiles'), 'error')
        return
    end

    local sanitized = SanitizeSettings(data.settings)

    DB.execute(
        'INSERT INTO f5_boost_profiles (identifier, slot, name, settings) VALUES (?, ?, ?, ?)',
        {identifier, nextSlot, name, json.encode(sanitized)}
    )

    TriggerClientEvent('f5_boost:client:receiveProfiles', src, GetProfiles(identifier))
    TriggerClientEvent('f5_boost:client:notify', src, Translate('notify_profile_saved'))
end)

RegisterNetEvent('f5_boost:server:deleteProfile', function(slot)
    local src = source
    if not dbReady then return end

    local identifier = GetIdentifier(src)
    if not identifier then return end

    slot = tonumber(slot)
    if not slot or slot < 1 or slot > maxProfiles then return end

    DB.execute(
        'DELETE FROM f5_boost_profiles WHERE identifier = ? AND slot = ?',
        {identifier, slot}
    )

    TriggerClientEvent('f5_boost:client:receiveProfiles', src, GetProfiles(identifier))
    TriggerClientEvent('f5_boost:client:notify', src, Translate('notify_profile_deleted'))
end)

RegisterNetEvent('f5_boost:server:setDefault', function(slot)
    local src = source
    if not dbReady then return end

    local identifier = GetIdentifier(src)
    if not identifier then return end

    DB.execute('UPDATE f5_boost_profiles SET is_default = 0 WHERE identifier = ?', {identifier})

    slot = tonumber(slot) or 0
    if slot >= 1 and slot <= maxProfiles then
        DB.execute(
            'UPDATE f5_boost_profiles SET is_default = 1 WHERE identifier = ? AND slot = ?',
            {identifier, slot}
        )
    end

    local msg = (slot >= 1 and slot <= maxProfiles) and Translate('notify_default_set') or Translate('notify_default_removed')
    TriggerClientEvent('f5_boost:client:receiveProfiles', src, GetProfiles(identifier))
    TriggerClientEvent('f5_boost:client:notify', src, msg)
end)

RegisterNetEvent('f5_boost:server:updateProfile', function(data)
    local src = source
    if not dbReady then return end

    local identifier = GetIdentifier(src)
    if not identifier then return end
    if not data or type(data.settings) ~= 'table' then return end

    local slot = tonumber(data.slot)
    if not slot or slot < 1 or slot > maxProfiles then return end

    local sanitized = SanitizeSettings(data.settings)

    DB.execute(
        'UPDATE f5_boost_profiles SET settings = ?, updated_at = CURRENT_TIMESTAMP WHERE identifier = ? AND slot = ?',
        {json.encode(sanitized), identifier, slot}
    )

    TriggerClientEvent('f5_boost:client:receiveProfiles', src, GetProfiles(identifier))
    TriggerClientEvent('f5_boost:client:notify', src, Translate('notify_profile_updated'))
end)

RegisterNetEvent('f5_boost:server:loadProfile', function(slot)
    local src = source
    if not dbReady then return end

    local identifier = GetIdentifier(src)
    if not identifier then return end

    slot = tonumber(slot)
    if not slot or slot < 1 or slot > maxProfiles then return end

    local rows = DB.query(
        'SELECT settings FROM f5_boost_profiles WHERE identifier = ? AND slot = ?',
        {identifier, slot}
    )

    if rows and #rows > 0 and rows[1].settings then
        local ok, settings = pcall(json.decode, rows[1].settings)
        if ok and type(settings) == 'table' then
            TriggerClientEvent('f5_boost:client:profileLoaded', src, settings)
            TriggerClientEvent('f5_boost:client:notify', src, Translate('notify_profile_loaded'))
        end
    end
end)
