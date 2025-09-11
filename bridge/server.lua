--- Dynamically selects and returns the appropriate function for retrieving a player object
--- based on the configured framework.
---@return function A function that returns the player object when called with server ID
local CreateGetPlayerFunction = function()
    if Framework == 'esx' then
        return function(source)
            return ESX.GetPlayerFromId(source)
        end
    elseif Framework == 'qb' or Framework == 'qbx' then
        return function(source)
            return QBCore.Functions.GetPlayer(source)
        end
    else
        return function(source)
            error(string.format("Unsupported framework. Unable to retrieve player object for source: %s", source))
            return nil
        end
    end
end

--- Creates framework-specific function for getting player identifier
---@return function Function to retrieve player identifier
local CreateGetIdentifierFunction = function()
    if Framework == 'esx' then
        return function(player)
            return player.identifier
        end
    elseif Framework == 'qb' or Framework == 'qbx' then
        return function(player)
            return player.PlayerData.citizenid
        end
    else
        return function()
            error("Unsupported framework for GetIdentifier.")
        end
    end
end

-- Initialize player management functions
GetPlayer = CreateGetPlayerFunction()
local GetIdentifierFromPlayer = CreateGetIdentifierFunction()

--- Gets a player's identifier
---@param source number The player's server ID
---@return string|nil The player's identifier
GetIdentifier = function(source)
    local player = GetPlayer(source)
    return player and GetIdentifierFromPlayer(player) or nil
end

--- Checks for updates by comparing local version with GitHub releases
---@param repo string The GitHub repository in format 'owner/repository'
CheckVersion = function(repo)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resource, 'Version', 0)
    
    if currentVersion then
        currentVersion = currentVersion:match('%d+%.%d+%.%d+')
    end
    
    if not currentVersion then
        return print("^1Unable to determine current resource version for '^2" .. resource .. "^1'^0")
    end
    
    print('^3Checking for updates for ^2' .. resource .. '^3...^0')
    
    SetTimeout(1000, function()
        local url = ('https://api.github.com/repos/%s/releases/latest'):format(repo)
        PerformHttpRequest(url, function(status, response)
            if status ~= 200 then
                print('^1Failed to fetch release information for ^2' .. resource .. '^1. HTTP status: ' .. status .. '^0')
                return
            end
            
            local data = json.decode(response)
            if not data then
                print('^1Failed to parse release information for ^2' .. resource .. '^1.^0')
                return
            end
            
            if data.prerelease then
                print('^3Skipping prerelease for ^2' .. resource .. '^3.^0')
                return
            end
            
            local latestVersion = data.tag_name and data.tag_name:match('%d+%.%d+%.%d+')
            if not latestVersion then
                print('^1Failed to get valid latest version for ^2' .. resource .. '^1.^0')
                return
            end
            
            if latestVersion == currentVersion then
                print('^2' .. resource .. ' ^3is up-to-date with version ^2' .. currentVersion .. '^3.^0')
                return
            end
            
            -- Compare versions
            local parseVersion = function(version)
                local parts = {}
                for part in version:gmatch('%d+') do
                    table.insert(parts, tonumber(part))
                end
                return parts
            end
            
            local cv = parseVersion(currentVersion)
            local lv = parseVersion(latestVersion)
            
            for i = 1, math.max(#cv, #lv) do
                local current = cv[i] or 0
                local latest = lv[i] or 0
                
                if current < latest then
                    local releaseNotes = data.body or "No release notes available."
                    local message = releaseNotes:find("\n") and 
                        "Check release page or changelog channel on Discord for more information!" or 
                        releaseNotes
                    
                    print(string.format(
                        '^3An update is available for ^2%s^3 (current: ^2%s^3)\r\nLatest: ^2%s^3\r\nRelease Notes: ^7%s',
                        resource, currentVersion, latestVersion, message
                    ))
                    break
                elseif current > latest then
                    print(string.format(
                        '^2%s ^3has newer local version (^2%s^3) than latest public release (^2%s^3).^0',
                        resource, currentVersion, latestVersion
                    ))
                    break
                end
            end
        end, 'GET', '')
    end)
end