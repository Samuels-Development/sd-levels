-- Flag to track whether the levels UI is visible
local levelsVisible = false

-- Table to store the player's levels data
local levels = {}

-- Function to update the levels data in the UI.
---@param levelsData A table containing the levels data to display.
local UpdateLevelsUI = function(levelsData)
    SendNUIMessage({
        action = "updateLevels",
        levels = levelsData
    })
end

-- Function to toggle the visibility of the levels UI.
---@param show A boolean indicating whether to show or hide the UI.
local ToggleLevelsUI = function(show)
    levelsVisible = show
    SendNUIMessage({
        action = "toggleUI",
        show = levelsVisible
    })
    SetNuiFocus(levelsVisible, levelsVisible)
end

-- Event handler for closing the UI
RegisterNUICallback('closeUI', function(data, cb)
    ToggleLevelsUI(false)
    cb('ok')
end)

-- Event handler for receiving levels data from the server
RegisterNetEvent('sd-levels:client:updateLevels', function(serverLevels)
    if serverLevels then
        levels = serverLevels
        UpdateLevelsUI(levels)
    end
end)

RegisterCommand("levels", function()
    ToggleLevelsUI(true)
end, false)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TriggerServerEvent('sd-levels:server:syncData')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(500)
    TriggerServerEvent('sd-levels:server:syncData')
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(500)
    TriggerServerEvent('sd-levels:server:syncData')
end)

RegisterNetEvent('sd-levels:radialOpen', function()
    TriggerServerEvent('sd-levels:server:syncData')
    ToggleLevelsUI(true)
end)