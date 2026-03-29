local menuOpen = false
local currentSettings = {}
local settingsActive = false
local cameraFree = false
local cachedPed = nil
local cachedPedTick = 0

local ToggleMenu, ApplyGraphicsPreset, ApplyPerformanceMode
local ApplySliderSetting, ApplyToggleSetting, ApplyAllToggles, ApplyAllSettings

local VANILLA_SETTINGS = {
    graphicsPreset = 'none',
    performanceMode = 'none',
    shadowDistance = 100,
    objectQuality = 100,
    characterQuality = 100,
    vehicleDistance = 100,
    toggleClearEvents = false,
    toggleLightReflections = true,
    toggleRainWind = true,
    toggleBloodStains = true,
    toggleFireEffects = true,
    toggleScenarios = true,
}

local function deepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == 'table' and deepCopy(v) or v
    end
    return copy
end

local function GetCachedPed()
    local tick = GetGameTimer()
    if tick - cachedPedTick > 1000 then
        cachedPed = PlayerPedId()
        cachedPedTick = tick
    end
    return cachedPed
end

local KVP_KEY = 'fps_menu_settings'

local function SaveSettings()
    SetResourceKvp(KVP_KEY, json.encode(currentSettings))
end

local function LoadSettings()
    local raw = GetResourceKvpString(KVP_KEY)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            local settings = deepCopy(VANILLA_SETTINGS)
            for k, v in pairs(decoded) do
                if settings[k] ~= nil then
                    settings[k] = v
                end
            end
            return settings, true
        end
    end
    return deepCopy(VANILLA_SETTINGS), false
end

local function ApplyMergedSettings(settings, sendNUI)
    settingsActive = true
    local merged = deepCopy(VANILLA_SETTINGS)
    for k, v in pairs(settings) do
        if merged[k] ~= nil then merged[k] = v end
    end
    currentSettings = merged
    ApplyAllSettings()
    SaveSettings()
    if sendNUI then
        SendNUIMessage({
            action = 'updateSettings',
            settings = currentSettings
        })
    end
end

CreateThread(function()
    local hasKvp
    currentSettings, hasKvp = LoadSettings()
    settingsActive = hasKvp

    RegisterCommand(Config.Command, function()
        ToggleMenu()
    end, false)

    RegisterKeyMapping(Config.Command, 'Open FPS Menu', 'keyboard', Config.OpenKey)

    Wait(3000)

    if settingsActive then
        ApplyAllSettings()
    end

    TriggerServerEvent('f5_boost:server:getDefaultProfile')
end)

RegisterNUICallback('requestLocales', function(_, cb)
    cb(GetLocaleTable())
end)

RegisterNUICallback('closeMenu', function(_, cb)
    menuOpen = false
    if cameraFree then
        cameraFree = false
        SetNuiFocusKeepInput(false)
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('applyGraphicsPreset', function(data, cb)
    if data and data.preset then
        settingsActive = true
        currentSettings.graphicsPreset = data.preset
        ApplyGraphicsPreset(data.preset)
        SaveSettings()
    end
    cb('ok')
end)

RegisterNUICallback('applyPerformanceMode', function(data, cb)
    if data and data.mode then
        settingsActive = true
        currentSettings.performanceMode = data.mode
        ApplyPerformanceMode(data.mode)
        SaveSettings()
    end
    cb('ok')
end)

RegisterNUICallback('applySlider', function(data, cb)
    if data and data.setting and data.value then
        settingsActive = true
        currentSettings[data.setting] = tonumber(data.value) or 50
        ApplySliderSetting(data.setting, currentSettings[data.setting])
        SaveSettings()
    end
    cb('ok')
end)

RegisterNUICallback('applyToggle', function(data, cb)
    if data and data.setting ~= nil and data.value ~= nil then
        settingsActive = true
        currentSettings[data.setting] = data.value
        ApplyToggleSetting(data.setting, data.value)
        SaveSettings()
    end
    cb('ok')
end)

RegisterNUICallback('resetDefaults', function(_, cb)
    ApplyMergedSettings({}, true)
    cb('ok')
end)

RegisterNUICallback('saveProfile', function(data, cb)
    if data and data.name and #tostring(data.name) > 0 then
        TriggerServerEvent('f5_boost:server:saveProfile', {
            name = tostring(data.name),
            settings = currentSettings
        })
    end
    cb('ok')
end)

RegisterNUICallback('deleteProfile', function(data, cb)
    if data and data.slot then
        TriggerServerEvent('f5_boost:server:deleteProfile', tonumber(data.slot))
    end
    cb('ok')
end)

RegisterNUICallback('setDefault', function(data, cb)
    local slot = data and tonumber(data.slot) or 0
    TriggerServerEvent('f5_boost:server:setDefault', slot)
    cb('ok')
end)

RegisterNUICallback('updateProfile', function(data, cb)
    if data and data.slot then
        TriggerServerEvent('f5_boost:server:updateProfile', {
            slot = tonumber(data.slot),
            settings = currentSettings
        })
    end
    cb('ok')
end)

RegisterNUICallback('loadProfile', function(data, cb)
    if data and data.slot then
        TriggerServerEvent('f5_boost:server:loadProfile', tonumber(data.slot))
    end
    cb('ok')
end)

RegisterNUICallback('importProfile', function(data, cb)
    if data and data.settings and type(data.settings) == 'table' then
        ApplyMergedSettings(data.settings, true)
    end
    cb('ok')
end)

RegisterNetEvent('f5_boost:client:notify', function(message, type)
    SendNUIMessage({
        action = 'notify',
        message = message or '',
        type = type or 'success'
    })
end)

RegisterNetEvent('f5_boost:client:receiveProfiles', function(profiles)
    SendNUIMessage({
        action = 'updateProfiles',
        profiles = profiles or {}
    })
end)

RegisterNetEvent('f5_boost:client:profileLoaded', function(settings)
    if settings and type(settings) == 'table' then
        ApplyMergedSettings(settings, true)
    end
end)

RegisterNetEvent('f5_boost:client:applyDefaultProfile', function(settings)
    if settingsActive then return end
    if settings and type(settings) == 'table' then
        ApplyMergedSettings(settings, false)
    end
end)

RegisterNUICallback('startCameraControl', function(_, cb)
    if menuOpen then
        cameraFree = true
        SetNuiFocusKeepInput(true)
    end
    cb('ok')
end)

RegisterNUICallback('stopCameraControl', function(_, cb)
    cameraFree = false
    SetNuiFocusKeepInput(false)
    cb('ok')
end)

CreateThread(function()
    while true do
        if cameraFree then
            Wait(0)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 68, true)
            DisableControlAction(0, 69, true)
            DisableControlAction(0, 70, true)
            DisableControlAction(0, 91, true)
            DisableControlAction(0, 92, true)
            DisableControlAction(0, 114, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
        else
            Wait(200)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
    end
end)

ToggleMenu = function()
    menuOpen = not menuOpen
    if cameraFree then
        cameraFree = false
        SetNuiFocusKeepInput(false)
    end
    SetNuiFocus(menuOpen, menuOpen)
    SendNUIMessage({
        action = menuOpen and 'openMenu' or 'closeMenu',
        settings = currentSettings,
        openKey = Config.OpenKey,
        maxProfiles = Config.MaxProfiles or 5
    })
    if menuOpen then
        TriggerServerEvent('f5_boost:server:requestProfiles')
    end
end

local graphicsPresets = {
    ultra = {
        shadowDistance = 100,
        objectQuality = 100,
        characterQuality = 100,
        vehicleDistance = 100,
    },
    high = {
        shadowDistance = 80,
        objectQuality = 80,
        characterQuality = 80,
        vehicleDistance = 80,
    },
    balanced = {
        shadowDistance = 50,
        objectQuality = 50,
        characterQuality = 50,
        vehicleDistance = 50,
    },
    medium = {
        shadowDistance = 40,
        objectQuality = 40,
        characterQuality = 40,
        vehicleDistance = 40,
    },
    low = {
        shadowDistance = 25,
        objectQuality = 25,
        characterQuality = 25,
        vehicleDistance = 25,
    },
    potato = {
        shadowDistance = 10,
        objectQuality = 10,
        characterQuality = 10,
        vehicleDistance = 10,
    },
    minimal = {
        shadowDistance = 0,
        objectQuality = 5,
        characterQuality = 5,
        vehicleDistance = 5,
    },
}

ApplyGraphicsPreset = function(preset)
    local p = graphicsPresets[preset]
    if not p then return end

    for k, v in pairs(p) do
        currentSettings[k] = v
    end

    ApplyAllSettings()
    SendNUIMessage({
        action = 'updateSettings',
        settings = currentSettings
    })
end

ApplyPerformanceMode = function(mode)
    if mode == 'quality' then
        currentSettings.toggleLightReflections = true
        currentSettings.toggleRainWind = true
        currentSettings.toggleBloodStains = true
        currentSettings.toggleFireEffects = true
        currentSettings.toggleScenarios = true
        currentSettings.toggleClearEvents = false
    elseif mode == 'balanced' then
        currentSettings.toggleLightReflections = true
        currentSettings.toggleRainWind = true
        currentSettings.toggleBloodStains = false
        currentSettings.toggleFireEffects = true
        currentSettings.toggleScenarios = false
        currentSettings.toggleClearEvents = false
    elseif mode == 'performance' then
        currentSettings.toggleLightReflections = false
        currentSettings.toggleRainWind = false
        currentSettings.toggleBloodStains = false
        currentSettings.toggleFireEffects = false
        currentSettings.toggleScenarios = false
        currentSettings.toggleClearEvents = true
    end

    ApplyAllToggles()
    SendNUIMessage({
        action = 'updateSettings',
        settings = currentSettings
    })
end

ApplySliderSetting = function(setting, value)
    local val = (tonumber(value) or 50) / 100.0

    if setting == 'shadowDistance' then
        CascadeShadowsSetCascadeBoundsScale(val)
        CascadeShadowsEnableEntityTracker(val >= 0.3)
        CascadeShadowsSetEntityTrackerScale(val)
        if val < 0.15 then
            CascadeShadowsSetAircraftMode(false)
            CascadeShadowsSetDynamicDepthMode(false)
            CascadeShadowsSetDynamicDepthValue(0.0)
        else
            CascadeShadowsSetAircraftMode(true)
            CascadeShadowsSetDynamicDepthMode(true)
            CascadeShadowsSetDynamicDepthValue(val)
        end
    elseif setting == 'vehicleDistance' then
        SetFarDrawVehicles(val >= 0.3)
    end
end

ApplyToggleSetting = function(setting, value)
    if setting == 'toggleClearEvents' then
        if value then
            ClearAllBrokenGlass()
            RemoveDecalsInRange(GetEntityCoords(GetCachedPed()), 1000.0)
        end
    elseif setting == 'toggleLightReflections' then
        SetArtificialLightsState(not value)
        SetArtificialLightsStateAffectsVehicles(false)
    elseif setting == 'toggleRainWind' then
        if not value then
            SetRainLevel(0.0)
            SetWindSpeed(0.0)
            SetWindDirection(0.0)
        end
    elseif setting == 'toggleBloodStains' then
        if not value then
            ClearPedBloodDamage(GetCachedPed())
            ClearPedLastWeaponDamage(GetCachedPed())
        end
    end
end

ApplyAllToggles = function()
    for _, toggle in ipairs({
        'toggleClearEvents',
        'toggleLightReflections',
        'toggleRainWind',
        'toggleBloodStains',
        'toggleFireEffects',
        'toggleScenarios',
    }) do
        ApplyToggleSetting(toggle, currentSettings[toggle])
    end
end

local function ApplyDensityToggles()
    local charVal = (currentSettings.characterQuality or 50) / 100.0
    local vehVal = (currentSettings.vehicleDistance or 50) / 100.0
    local charEnabled = charVal >= 0.3
    local vehEnabled = vehVal >= 0.3

    SetGarbageTrucks(charEnabled)
    SetRandomBoats(charEnabled)
    SetRandomTrains(charEnabled)
    SetCreateRandomCops(charEnabled)
    SetCreateRandomCopsNotOnScenarios(charEnabled)

    SetFarDrawVehicles(vehEnabled)
    DistantCopCarSirens(vehEnabled)
end

ApplyAllSettings = function()
    ApplySliderSetting('shadowDistance', currentSettings.shadowDistance)
    ApplySliderSetting('vehicleDistance', currentSettings.vehicleDistance)
    ApplyAllToggles()

    local objVal = (currentSettings.objectQuality or 50) / 100.0

    SetForceVehicleTrails(objVal >= 0.3)
    SetForcePedFootstepsTracks(objVal >= 0.3)

    local lowQuality = objVal < 0.3
    SetReducePedModelBudget(lowQuality)
    SetReduceVehicleModelBudget(lowQuality)

    ApplyDensityToggles()
end

CreateThread(function()
    while true do
        if settingsActive then
            Wait(0)

            local charVal = (currentSettings.characterQuality or 50) / 100.0
            local vehVal = (currentSettings.vehicleDistance or 50) / 100.0

            SetPedDensityMultiplierThisFrame(charVal)
            SetRandomVehicleDensityMultiplierThisFrame(charVal)
            SetParkedVehicleDensityMultiplierThisFrame(vehVal)
            SetVehicleDensityMultiplierThisFrame(vehVal)
            SetScenarioPedDensityMultiplierThisFrame(
                currentSettings.toggleScenarios and 1.0 or 0.0,
                currentSettings.toggleScenarios and 1.0 or 0.0
            )

            SetAmbientPedRangeMultiplierThisFrame(charVal)
            SetAmbientVehicleRangeMultiplierThisFrame(vehVal)

            local objVal = (currentSettings.objectQuality or 50) / 100.0
            OverrideLodscaleThisFrame(0.2 + objVal * 0.8)

            if currentSettings.performanceMode == 'performance' then
                SuppressShockingEventsNextFrame()
            end

            if not currentSettings.toggleRainWind then
                SetRainLevel(0.0)
            end

            if currentSettings.toggleClearEvents then
                SetDisableDecalRenderingThisFrame()
            end
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if not settingsActive then goto continue end

        local ped = GetCachedPed()
        local coords = GetEntityCoords(ped)

        if not currentSettings.toggleBloodStains then
            ClearPedBloodDamage(ped)
        end

        if currentSettings.toggleClearEvents then
            ClearAllBrokenGlass()
            RemoveDecalsInRange(coords, 250.0)
            ClearAreaOfProjectiles(coords, 250.0, false)
            RemoveParticleFxInRange(coords, 250.0)
        end

        if not currentSettings.toggleFireEffects then
            StopFireInRange(coords, 250.0)
        end

        ApplyDensityToggles()

        if currentSettings.performanceMode == 'performance' then
            ClearAreaOfCops(coords, 400.0, 0)
        end

        ::continue::
    end
end)

CreateThread(function()
    Wait(5000)
    if Config.DisableDispatch then
        for i = 1, 15 do
            EnableDispatchService(i, false)
        end
    end
end)

if Config.ShowFPSCounter then
    CreateThread(function()
        local lastTime = GetGameTimer()
        local frames = 0
        local fps = 0

        while true do
            Wait(0)
            frames = frames + 1
            local now = GetGameTimer()

            if now - lastTime >= 1000 then
                fps = frames
                frames = 0
                lastTime = now

                if menuOpen then
                    SendNUIMessage({
                        action = 'updateFPS',
                        fps = fps
                    })
                end
            end
        end
    end)
end
