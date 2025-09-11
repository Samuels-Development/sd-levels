-- Table to store player XP data
local playerXP = {}

-- Table to store level configuration
local levelConfig = require('levels')

CreateThread(function()
    -- Create the players_xp table if it doesn't exist
    local createTableQuery = [[
        CREATE TABLE IF NOT EXISTS `players_xp` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(255) NOT NULL UNIQUE,
            `xp_data` LONGTEXT NOT NULL,
            PRIMARY KEY (`id`)
        );
    ]]
    
    -- Execute the query
    MySQL.Async.execute(createTableQuery, {}, function(rowsChanged)
        print("^2[LEVELS]^7 Database table 'players_xp' checked/created successfully")
    end)
end)

-- Retrieves the player's current XP in a level.
---@param playerId The player's server ID.
---@param levelName The name of the level.
---@return The player's current XP in the level.
local GetPlayerXP = function(playerId, levelName)
    return playerXP[playerId] and playerXP[playerId][levelName] or 0
end

exports("GetPlayerXP", GetPlayerXP)

-- Calculates the player's progress in a level
---@param xp number The player's total XP in the level.
---@param totalXP number The cumulative total XP required for all levels up to the current level.
---@param xpRequired number The amount of XP required for the current level.
---@return number The player's progress towards the next level as a percentage.
local CalculateProgress = function(xp, totalXP, xpRequired)
    local xpIntoLevel = xp - (totalXP - xpRequired)
    return (xpIntoLevel / xpRequired) * 100
end

-- Determines the player's level and progress in a level based on their XP.
---@param playerId The player's server ID.
---@param levelName The name of the level.
---@return A table containing the level and progress percentage.
local GetPlayerLevelAndProgress = function(playerId, levelName)
    local level = levelConfig[levelName]
    if not level or not level.xpPerLevel then
        return { level = 1, progress = 0 }
    end

    local xp = GetPlayerXP(playerId, levelName)
    local totalXP = 0

    for lvl, xpRequired in ipairs(level.xpPerLevel) do
        totalXP = totalXP + xpRequired
        if xp < totalXP then
            local progress = CalculateProgress(xp, totalXP, xpRequired)
            return { level = lvl, progress = progress }
        end
    end

    return { level = #level.xpPerLevel, progress = 100 }
end

exports("GetPlayerLevelAndProgress", GetPlayerLevelAndProgress)

-- Sends levels data to the client
---@param playerId The player's server ID.
local SendLevelsDataToClient = function(playerId)
    local levelsData = {}
    
    for levelName, levelConfig in pairs(levelConfig) do
        local xpAmount = GetPlayerXP(playerId, levelName)
        local levelData = GetPlayerLevelAndProgress(playerId, levelName)
        
        levelsData[levelName] = {
            name = levelName,
            xp = xpAmount,
            level = levelData.level,
            progress = levelData.progress,
            description = levelConfig.description or nil,
            maxLevel = levelConfig.xpPerLevel and #levelConfig.xpPerLevel + 1 or 10,
        }
    end
    
    TriggerClientEvent('sd-levels:client:updateLevels', playerId, levelsData)
end

-- Saves the player's XP data to the database.
---@param playerId The player's server ID.
local SavePlayerXPToDatabase = function(playerId)
    local identifier = SD.GetIdentifier(playerId)
    local serializedXPData = json.encode(playerXP[playerId])

    MySQL.Async.execute("UPDATE players_xp SET xp_data = @xp_data WHERE identifier = @identifier", {
        ['@identifier'] = identifier,
        ['@xp_data'] = serializedXPData
    })
end

-- Loads the player's XP data from the database and calls a callback once loaded.
---@param playerId The player's server ID.
---@param callback The callback function to execute after the data is loaded.
local LoadPlayerXPFromDatabase = function(playerId, callback)
    local identifier = SD.GetIdentifier(playerId)
    MySQL.Async.fetchAll("SELECT xp_data FROM players_xp WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            playerXP[playerId] = json.decode(result[1].xp_data) or {}
        else
            playerXP[playerId] = {}
            MySQL.Async.execute("INSERT INTO players_xp (identifier, xp_data) VALUES (@identifier, @xp_data)", {
                ['@identifier'] = identifier,
                ['@xp_data'] = json.encode({})
            })
        end
        if callback then
            callback()
        end
    end)
end

-- Initializes a player's XP data and sends it to the client after it's loaded.
---@param playerId The player's server ID.
local InitializePlayerXP = function(playerId)
    if playerXP[playerId] then
        SendLevelsDataToClient(playerId)
    else
        LoadPlayerXPFromDatabase(playerId, function()
            SendLevelsDataToClient(playerId)
        end)
    end
end

-- Sets the player's XP in a level.
---@param playerId The player's server ID.
---@param levelName The name of the level.
---@param xpAmount The new XP amount to set.
local SetPlayerXP = function(playerId, levelName, xpAmount)
    InitializePlayerXP(playerId)
    playerXP[playerId][levelName] = xpAmount
    SavePlayerXPToDatabase(playerId)
    SendLevelsDataToClient(playerId)
end

exports("SetPlayerXP", SetPlayerXP)

-- Modifies a player's XP in a specific level by a given amount (positive or negative).
---@param playerId The player's server ID.
---@param levelName The name of the level.
---@param amount The amount of XP to adjust (can be positive or negative).
local ModifyPlayerXP = function(playerId, levelName, amount)
    if amount == 0 then return end

    local level = levelConfig[levelName]
    if not level or not level.xpPerLevel then return end

    local currentXP = GetPlayerXP(playerId, levelName) or 0

    if not level.maxTotalXP then
        local totalXP = 0
        for _, xpRequired in ipairs(level.xpPerLevel) do
            totalXP = totalXP + xpRequired
        end
        level.maxTotalXP = totalXP
    end

    local newXP = currentXP + amount
    newXP = math.max(0, math.min(newXP, level.maxTotalXP))

    SetPlayerXP(playerId, levelName, newXP)
end

-- Increases a player's XP in a level by a given amount.
---@param playerId The player's server ID.
---@param levelName The name of the level.
---@param amount The amount of XP to add.
local IncreasePlayerXP = function(playerId, levelName, amount)
    ModifyPlayerXP(playerId, levelName, amount)
end

exports("IncreasePlayerXP", IncreasePlayerXP)

-- Decreases a player's XP in a level by a given amount.
---@param playerId The player's server ID.
---@param levelName The name of the level.
---@param amount The amount of XP to remove.
local DecreasePlayerXP = function(playerId, levelName, amount)
    ModifyPlayerXP(playerId, levelName, -amount)
end

exports("DecreasePlayerXP", DecreasePlayerXP)

-- Event handler for initial levels data request
RegisterNetEvent('sd-levels:server:syncData', function()
    local playerId = source

    if playerXP[playerId] then
        return
    end

    InitializePlayerXP(playerId)
end)

-- Event handler for player disconnection.
AddEventHandler('playerDropped', function()
    local playerId = source
    playerXP[playerId] = nil
end)

SD.CheckVersion('Samuels-Development/sd-levels') -- Check version of specified resource