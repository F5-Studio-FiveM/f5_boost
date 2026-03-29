function Translate(key)
    local lang = Config.Locale or 'en'
    local tbl = _G['Locales_' .. lang]
    if not tbl then tbl = _G['Locales_en'] end
    if not tbl then return key end
    return tbl[key] or (_G['Locales_en'] and _G['Locales_en'][key]) or key
end

function GetLocaleTable()
    local lang = Config.Locale or 'en'
    return _G['Locales_' .. lang] or _G['Locales_en'] or {}
end
