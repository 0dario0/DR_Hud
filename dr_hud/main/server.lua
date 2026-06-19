PlayerStress = {}
stressData = {}
NitroVeh = {}
Framework = nil

-- ============================================================
-- Framework inicializace (serverside)
-- ============================================================
if Config.Framework == "ESX" then
    -- Stará ESX: čekáme na event
    AddEventHandler('esx:onPlayerSpawn', function() end) -- dummy, jen aby ESX bylo načteno
    Citizen.CreateThread(function()
        while Framework == nil do
            TriggerEvent('esx:getSharedObject', function(obj) Framework = obj end)
            Citizen.Wait(200)
        end
    end)
elseif Config.Framework == "NewESX" then
    Framework = exports['es_extended']:getSharedObject()
elseif Config.Framework == "QBCore" or Config.Framework == "OLDQBCore" then
    Framework = exports['qb-core']:GetCoreObject()
end

-- Helper: čekej dokud Framework není připravený
local function WaitForFramework()
    while Framework == nil do
        Citizen.Wait(100)
    end
end

-- Helper: je to ESX?
local function IsESX()
    return Config.Framework == "ESX" or Config.Framework == "NewESX"
end

-- Helper: získej hráče dle source
local function GetPlayer(src)
    if IsESX() then
        return Framework.GetPlayerFromId(src)
    else
        return Framework.Functions.GetPlayer(src)
    end
end

-- Helper: job name
local function GetJobName(player)
    if IsESX() then
        return player.job and player.job.name or ""
    else
        return player.PlayerData and player.PlayerData.job and player.PlayerData.job.name or ""
    end
end

-- Helper: identifier
local function GetPlayerIdentifier(player)
    if IsESX() then
        return player.getIdentifier and player.getIdentifier() or "0"
    else
        return player.PlayerData and player.PlayerData.citizenid or "0"
    end
end

-- ============================================================
-- Spuštění po načtení Frameworku
-- ============================================================
Citizen.CreateThread(function()
    WaitForFramework()

    -- Trigger load pro všechny online hráče
    Citizen.Wait(2000)
    for _, v in pairs(GetPlayers()) do
        local player = GetPlayer(tonumber(v))
        if player ~= nil then
            TriggerClientEvent('HudPlayerLoad', tonumber(v))
            Citizen.Wait(74)
        end
    end

    -- Registrace usable itemu pro nitro
    Citizen.Wait(1500)
    local UsableItem
    if IsESX() then
        UsableItem = Framework.RegisterUsableItem
    else
        UsableItem = Framework.Functions.CreateUseableItem
    end

    if UsableItem then
        UsableItem(Config.NitroItem, function(source)
            TriggerClientEvent('SetupNitro', source)
        end)
    end

    -- ============================================================
    -- ESX Callback a eventy
    -- ============================================================
    if IsESX() then
        Framework.RegisterServerCallback('GET', function(source, cb)
            local xPlayer = Framework.GetPlayerFromId(source)
            if xPlayer ~= nil then
                local data = {
                    [1] = Config.Server[1],
                    [2] = Config.Server[2],
                    ping = GetPlayerPing(source),
                    totalPlayers = #Framework.GetPlayers(),
                    cash = xPlayer.getMoney(),
                }
                cb(data)
            else
                cb(nil)
            end
        end)

        RegisterCommand(Config.Refresh, function(source)
            TriggerClientEvent('HudPlayerLoad', source)
        end)

        RegisterNetEvent('esx:playerLoaded')
        AddEventHandler('esx:playerLoaded', function(src)
            Citizen.Wait(1000)
            TriggerClientEvent('HudPlayerLoad', src)
        end)

    -- ============================================================
    -- QBCore Callback a eventy
    -- ============================================================
    elseif Config.Framework == "QBCore" or Config.Framework == "OLDQBCore" then
        Framework.Functions.CreateCallback('GET', function(source, cb)
            local xPlayer = Framework.Functions.GetPlayer(source)
            if xPlayer ~= nil then
                local data = {
                    [1] = Config.Server[1],
                    [2] = Config.Server[2],
                    ping = GetPlayerPing(source),
                    totalPlayers = #GetPlayers(),
                    cash = xPlayer.PlayerData.money['cash'],
                }
                cb(data)
            else
                cb(nil)
            end
        end)

        RegisterCommand(Config.Refresh, function(source)
            TriggerClientEvent('HudPlayerLoad', source)
        end)

        RegisterNetEvent('QBCore:Server:OnPlayerLoaded')
        AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
            local src = source
            Citizen.Wait(1000)
            TriggerClientEvent('HudPlayerLoad', src)
        end)
    end
end)

-- ============================================================
-- Stress eventy
-- ============================================================
RegisterNetEvent('SetStress', function(amount)
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    local jobName = GetJobName(player)
    local id = GetPlayerIdentifier(player)
    if Config.DisablePoliceStress and jobName == 'police' then return end
    if not PlayerStress[id] then PlayerStress[id] = 0 end
    local newStress = math.max(0, math.min(100, PlayerStress[id] + amount))
    PlayerStress[id] = newStress
    TriggerClientEvent('UpdateStress', src, newStress)
end)

RegisterNetEvent('hud:server:GainStress', function(amount)
    local src = source
    if IsWhitelisted(src) then return end
    local id = GetIdentifier(src)
    local newStress = math.min((tonumber(stressData[id]) or 0) + amount, 100)
    stressData[id] = math.max(newStress, 0)
    TriggerClientEvent('hud:client:UpdateStress', src, stressData[id])
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    local src = source
    local id = GetIdentifier(src)
    local newStress = math.max((tonumber(stressData[id]) or 0) - amount, 0)
    stressData[id] = math.min(newStress, 100)
    TriggerClientEvent('hud:client:UpdateStress', src, stressData[id])
end)

-- ============================================================
-- Helper funkce
-- ============================================================
function IsWhitelisted(source)
    local player = GetPlayer(source)
    if not player then return false end
    local jobName = GetJobName(player)
    for _, v in pairs(Config.StressWhitelistJobs) do
        if jobName == v then return true end
    end
    return false
end

function GetIdentifier(source)
    local player = GetPlayer(tonumber(source))
    if not player then return "0" end
    return GetPlayerIdentifier(player)
end
