-- Framework detection function
local DetectFramework = function()
    if GetResourceState('qb-core') == 'started' then
        return 'qb', exports['qb-core']:GetCoreObject()
    end
    
    if GetResourceState('es_extended') == 'started' then
        return 'esx', exports['es_extended']:getSharedObject()
    end
    
    return nil, nil
end

-- Detect and initialize framework
local framework, core = DetectFramework()

if not framework then
    error([[
        ^1CRITICAL ERROR: No supported framework detected!^0
        ^3This resource requires one of the following frameworks:^0
        - QBCore (qb-core)  
        - ESX (es_extended)
        
        Please ensure your framework is started before this resource.
    ]])
    return
end

Framework = framework
Core = core

-- Set framework-specific globals for compatibility
if Framework == 'qb' then
    QBCore = Core
elseif Framework == 'esx' then
    ESX = Core
end