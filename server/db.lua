DB = {}

local detected = nil
local ready = false

local function Detect()
    for _, name in ipairs({'oxmysql', 'mysql-async', 'ghmattimysql'}) do
        if GetResourceState(name) == 'started' then
            return name
        end
    end
    return nil
end

function DB.ready(cb)
    CreateThread(function()
        local attempts = 0
        while not detected and attempts < 300 do
            detected = Detect()
            if not detected then
                Wait(100)
                attempts = attempts + 1
            end
        end

        if not detected then
            print('^1[f5_boost] No MySQL resource detected (oxmysql / mysql-async / ghmattimysql)^0')
            return
        end

        if detected == 'mysql-async' then
            local tries = 0
            while tries < 100 do
                local ok, result = pcall(function() return exports['mysql-async']:is_ready() end)
                if ok and result then break end
                Wait(100)
                tries = tries + 1
            end
            if tries >= 100 then
                print('^1[f5_boost] mysql-async is_ready() timed out^0')
                return
            end
        end

        ready = true
        print('^2[f5_boost] MySQL bridge: ' .. detected .. '^0')
        if cb then cb() end
    end)
end

function DB.query(sql, params)
    if not ready then return {} end
    params = params or {}

    if detected == 'oxmysql' then
        return exports.oxmysql:query_async(sql, params) or {}

    elseif detected == 'mysql-async' then
        local res, done = nil, false
        exports['mysql-async']:mysql_fetch_all(sql, params, function(r)
            res = r; done = true
        end)
        while not done do Wait(0) end
        return res or {}

    elseif detected == 'ghmattimysql' then
        return exports.ghmattimysql:executeSync(sql, params) or {}
    end

    return {}
end

function DB.execute(sql, params)
    if not ready then return 0 end
    params = params or {}

    if detected == 'oxmysql' then
        return exports.oxmysql:update_async(sql, params) or 0

    elseif detected == 'mysql-async' then
        local res, done = nil, false
        exports['mysql-async']:mysql_execute(sql, params, function(r)
            res = r; done = true
        end)
        while not done do Wait(0) end
        return res or 0

    elseif detected == 'ghmattimysql' then
        local res = exports.ghmattimysql:executeSync(sql, params)
        if type(res) == 'table' then return res.affectedRows or 0 end
        return res or 0
    end

    return 0
end
