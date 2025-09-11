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

--- Function to toggle the visibility of the levels UI.
---@param show A boolean indicating whether to show or hide the UI.
local ToggleLevelsUI = function(show)
    levelsVisible = show
    if show then
        TriggerServerEvent('sd-levels:server:syncData')
        SetNuiFocus(true, true)
    else
        SetNuiFocus(false, false)
    end
    SendNUIMessage({
        action = "toggleUI",
        show = levelsVisible
    })
end

--- Function to show loading state in UI
--- @param show boolean Whether to show loading state
local ShowLoadingState = function(show)
    SendNUIMessage({
        action = "setLoading",
        loading = show
    })
end

RegisterNUICallback('closeUI', function(data, cb)
    levelsVisible = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "toggleUI",
        show = false
    })
    cb('ok')
end)

-- Event handler for receiving levels data from the server
RegisterNetEvent('sd-levels:client:updateLevels', function(serverLevels)
    if serverLevels then
        levels = serverLevels
        UpdateLevelsUI(levels)
    end
end)

-- Command to open the levels UI
RegisterCommand("levels", function()
    ShowLoadingState(true)
    TriggerServerEvent('sd-levels:server:syncData')
    Wait(100)
    ShowLoadingState(false)
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
    ShowLoadingState(true)
    TriggerServerEvent('sd-levels:server:syncData')
    Wait(100)
    ShowLoadingState(false)
    ToggleLevelsUI(true)
end)