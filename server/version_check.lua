local RESOURCE_NAME = GetCurrentResourceName()

local function parseVersion(versionStr)
    if not versionStr then return nil end
    local clean = versionStr:gsub('^v', '')
    local major, minor, patch = clean:match('^(%d+)%.(%d+)%.(%d+)')
    if not major then return nil end
    return {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch),
        raw = clean
    }
end

local function compareVersions(current, latest)
    if current.major ~= latest.major then
        return current.major < latest.major and -1 or 1
    end
    if current.minor ~= latest.minor then
        return current.minor < latest.minor and -1 or 1
    end
    if current.patch ~= latest.patch then
        return current.patch < latest.patch and -1 or 1
    end
    return 0
end

local function log(color, msg)
    print(string.format('%s[%s]^0 %s', color, RESOURCE_NAME, msg))
end

CreateThread(function()
    if Config.VersionCheck == false then return end

    local currentStr = GetResourceMetadata(RESOURCE_NAME, 'version', 0)
    local current = parseVersion(currentStr)
    if not current then
        log('^1', 'Version check failed: could not parse local version "' .. tostring(currentStr) .. '"')
        return
    end

    local repo = Config.GitHubRepo
    if not repo or repo == 'OWNER/f5_boost' then
        log('^3', 'Version check skipped: set Config.GitHubRepo to your GitHub repository (owner/repo)')
        return
    end

    local url = string.format('https://api.github.com/repos/%s/releases/latest', repo)

    PerformHttpRequest(url, function(status, response, headers)
        if status == 404 then
            log('^3', 'Version check: no releases found on GitHub yet')
            return
        end

        if status ~= 200 then
            log('^1', string.format('Version check failed: GitHub API returned HTTP %d', status))
            return
        end

        local data = json.decode(response)
        if not data or not data.tag_name then
            log('^1', 'Version check failed: could not parse GitHub response')
            return
        end

        local latest = parseVersion(data.tag_name)
        if not latest then
            log('^1', 'Version check failed: could not parse remote version "' .. tostring(data.tag_name) .. '"')
            return
        end

        local cmp = compareVersions(current, latest)

        if cmp == 0 then
            log('^2', string.format('v%s — Up to date!', current.raw))
        elseif cmp < 0 then
            log('^3', string.format('Update available! v%s -> v%s', current.raw, latest.raw))
            log('^3', 'Download: ' .. (data.html_url or string.format('https://github.com/%s/releases/latest', repo)))
        else
            log('^4', string.format('v%s — Development build (latest release: v%s)', current.raw, latest.raw))
        end
    end, 'GET', '', {['User-Agent'] = RESOURCE_NAME, ['Accept'] = 'application/vnd.github.v3+json'})
end)
