
local speedBuffer, velBuffer, pauseActive, isCarHud, speedMultiplier, PlayerData, SpeedType, seatbeltOn = {0.0,0.0}, {}, false, false, nil, nil, false
Framework = nil
Framework = GetFramework()
Citizen.CreateThread(function()
   while Framework == nil do Citizen.Wait(750) end
   Citizen.Wait(2500)
end)

Citizen.CreateThread(function()
   local lastTalking = false
   while true do
      Citizen.Wait(100)
      local talking = NetworkIsPlayerTalking(PlayerId())
      if talking ~= lastTalking then
         lastTalking = talking
         SendNUIMessage({ data = 'VOICE', talking = talking })
      end
   end
end)


function Fwv(entity)
   local hr = GetEntityHeading(entity) + 90.0
   if hr < 0.0 then hr = 360.0 + hr end
   hr = hr * 0.0174533
   return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end

RegisterKeyMapping('seatbelt', 'Toggle Seatbelt', 'keyboard', Config.SeatbeltControl)

RegisterCommand('seatbelt', function()
   local playerPed = PlayerPedId()
   if IsPedInAnyVehicle(playerPed, false) then
      local class = GetVehicleClass(GetVehiclePedIsUsing(playerPed))
      if class ~= 8 and class ~= 13 and class ~= 14 then
         if seatbeltOn then
            -- If you want, you can put a notification belt removed information:
         else
            -- If you want, you can put a notification belt buckled information:
         end
         seatbeltOn = not seatbeltOn
      end
   end
end, false)

Citizen.CreateThread(function()
   while true do
      local playerPed = PlayerPedId()
      local Veh = GetVehiclePedIsIn(playerPed, false)
      local isCarHud = true -- Replace as per your context.

      if isCarHud then
         if seatbeltOn then DisableControlAction(0, 75) end
         speedBuffer[2] = speedBuffer[1]
         speedBuffer[1] = GetEntitySpeed(Veh)

         velBuffer[2] = velBuffer[1]
         velBuffer[1] = GetEntityVelocity(Veh)

         if speedBuffer[2] and GetEntitySpeedVector(Veh, true).y > 1.0  and speedBuffer[1] > 15 and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255) then
            if not seatbeltOn then
               local co = GetEntityCoords(playerPed)
               local fw = Fwv(playerPed)
               SetEntityCoords(playerPed, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
               SetEntityVelocity(playerPed, velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
               Wait(500)
               SetPedToRagdoll(playerPed, 1000, 1000, 0, 0, 0, 0)
               seatbeltOn = false
            end
         end
      else
         Wait(3000)
      end
      Wait(0)
   end
end)

function getSeatbeltStatus() 
   return seatbeltOn
end

local hunger, thirst = 0, 0 

function handleStatus()
    SendNUIMessage({data = "STATUS", hunger = hunger, thirst = thirst})
end

function updateStatus(name, value)
   if name == "hunger" then
       hunger = math.floor(value / 10000)
   elseif name == "thirst" then
       thirst = math.floor(value / 10000)
   end
   handleStatus() 
end

local function calculateHealth(ped)
   local healthBase = GetEntityHealth(ped) - 100
   return GetEntityModel(ped) == `mp_f_freemode_01` and (healthBase + 25) or healthBase
end

local function sendPlayerStats(ped)
   SendNUIMessage({ data = 'HEALTH', health = calculateHealth(ped) })
   SendNUIMessage({ data = 'ARMOR',  armor = GetPedArmour(ped) })
end

Citizen.CreateThread(function()
   while true do
      Citizen.Wait(1000)
      local ped = PlayerPedId()
      sendPlayerStats(ped)
      Citizen.Wait(2500)
   end
end)

Citizen.CreateThread(function()
   local wait, Laststamina
   while true do
      local Player = PlayerId()
      local newstamina = GetPlayerSprintStaminaRemaining(Player)
      if IsPedInAnyVehicle(PlayerPed) then wait = 2100 end
      if Laststamina ~= newstamina then
         wait = 125
         if IsEntityInWater(PlayerPed) then
            stamina = GetPlayerUnderwaterTimeRemaining(Player) * 10
         else
            stamina = 100 - GetPlayerSprintStaminaRemaining(Player)
         end
         Laststamina = newstamina
         SendNUIMessage({
            data = 'STAMINA',
            stamina = math.ceil(stamina),
         })
      else
         wait = 1850
      end
      Citizen.Wait(wait)
   end
end)

RegisterNetEvent('esx:setAccountMoney', function(account)
   local accountType = (account.name == 'money' and 'CASH') or (account.name == 'bank' and 'BANK')
   if accountType then 
       SendNUIMessage({ data = 'ACCOUNT', type = accountType, amount = account.money })
   end
end)

Citizen.CreateThread(function()
   while true do
      Citizen.Wait(650)
      if IsPauseMenuActive() and not pauseActive then
         pauseActive = true
         SendNUIMessage({
            data = 'EXIT',
            args = false
         })
      end
      if not IsPauseMenuActive() and pauseActive then
         pauseActive = false
         SendNUIMessage({
            data = 'EXIT',
            args = true
         })
      end
   end
end)



Callback = (Config.Framework == "ESX" or Config.Framework == "NewESX") and Framework.TriggerServerCallback or Framework.Functions.TriggerCallback


RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
   PlayerData = Framework.Functions.GetPlayerData()
end)

--QBCore
RegisterNetEvent("QBCore:Player:SetPlayerData")
AddEventHandler("QBCore:Player:SetPlayerData", function(data)
   local accountType = 'CASH'
   SendNUIMessage({ data = 'ACCOUNT', type = accountType, amount = data.money.cash })
end)

AddEventHandler('onResourceStart', function(resourceName)
   if (GetCurrentResourceName() ~= resourceName) then return end
   PlayerData = Framework.Functions.GetPlayerData()
end)

if Config.Framework == "ESX" or Config.Framework == "NewESX" then

   RegisterNetEvent("esx_status:onTick")
   AddEventHandler("esx_status:onTick", function(data)
       for _, v in pairs(data) do
           updateStatus(v.name, v.val)
       end
   end)

   RegisterNetEvent('HudPlayerLoad')
   AddEventHandler('HudPlayerLoad', function(source)

       TriggerEvent('esx_status:getStatus', 'hunger', function(status) 
           updateStatus('hunger', status.val)
       end)

       Callback('GET', function(data) 
        SendNUIMessage({data = "LIVE", player = data})
      end) 
     
       TriggerEvent('esx_status:getStatus', 'thirst', function(status) 
           updateStatus('thirst', status.val)
       end)
   end)

   




elseif Config.Framework == 'QBCore' or Config.Framework == 'OLDQBCore' then

     RegisterNetEvent('HudPlayerLoad')
     AddEventHandler('HudPlayerLoad', function(source)

        Citizen.Wait(4000)
         local hunger = math.ceil(PlayerData.metadata["hunger"])
         local thirst = math.ceil(PlayerData.metadata["thirst"])
         SendNUIMessage({data = "STATUS", hunger = hunger, thirst = thirst})

         Callback('GET', function(data) 
            SendNUIMessage({data = "LIVE", player = data})
         end) 

     end)
end

Citizen.CreateThread(function()
    local LastStreetName1, LastStreetName2 = nil, nil
    while true do
       Citizen.Wait(2000)
      local Coords = GetEntityCoords(PlayerPedId())
      local Street1, Street2 = GetStreetNameAtCoord(Coords.x, Coords.y, Coords.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
      local StreetName1 = GetLabelText(GetNameOfZone(Coords.x, Coords.y, Coords.z))
      local StreetName2 = GetStreetNameFromHashKey(Street1)
      if StreetName1 ~= LastStreetName1 or StreetName2 ~= LastStreetName2 then
        if StreetName1 ~= nil and StreetName1 ~= "" and StreetName2 ~= nil and StreetName2 ~= "" then
          SendNUIMessage({
            data = 'STREET',
            StreetName1 = StreetName1,
            StreetName2 = StreetName2,
          })
          LastStreetName1, LastStreetName2 = StreetName1, StreetName2
        end
      end
      local wait = IsPedInAnyVehicle(PlayerPedId()) and 500 or 2000
      Citizen.Wait(wait)
    end
  end)

local lastFuelUpdate = 0
function getFuelLevel(vehicle)
    local updateTick = GetGameTimer()
    if (updateTick - lastFuelUpdate) > 2000 then
        lastFuelUpdate = updateTick
        LastFuel = math.floor(Config.GetVehFuel(vehicle))
    end
    return LastFuel
end

local LastData = {
    Speed = 0,
    Rpm = 0,
    Fuel = 0,
    Engine = false,
    Light = false,
    Seatbelt = false,
 }

 Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if IsPedInVehicle(ped, vehicle, true) and not pauseActive then
            local LightVal, LightLights, LightHighlights = GetVehicleLightsState(vehicle)
            local Light = LightLights == 1 or LightHighlights == 1
            local Speed, Rpm, Fuel, Engine, Seatbelt, Gear = GetEntitySpeed(vehicle), GetVehicleCurrentRpm(vehicle), getFuelLevel(vehicle), GetIsVehicleEngineRunning(vehicle), seatbeltOn, GetVehicleCurrentGear(vehicle)
            DisplayRadar(true)
            if LastData.Speed ~= Speed or LastData.Gear ~= Gear or LastData.Rpm ~= Rpm or LastData.Fuel ~= Fuel or LastData.Engine ~= Engine or LastData.Light ~= Light or LastData.Seatbelt ~= Seatbelt then
               if Gear == 0 then 
                  Gear = "N"
               end
                SendNUIMessage({
                    data = 'CAR',
                    speed = math.floor(Speed * 3.6),
                    rpm = math.ceil(Rpm * 75),
                    fuel = Fuel,
                    gear = Gear,
                    engine = Engine,
                    state = Light,
                    seatbelt = Seatbelt,
                })
                LastData.Speed, LastData.Rpm, LastData.Fuel, LastData.Engine, LastData.Light, LastData.Seatbelt, LastData.Gear = Speed, Rpm, Fuel, Engine, Light, Seatbelt, Gear
            end
        else
            SendNUIMessage({data = 'CIVIL'})
            DisplayRadar(false)
            SetRadarBigmapEnabled(false, false)
            SetRadarZoom(1000)
            Citizen.Wait(500)
        end
    end
 end)


Citizen.CreateThread(function()
    local defaultAspectRatio = 1920/1080 -- Don't change this.
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX/resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio-aspectRatio)/3.6)-0.008 -- Adjust this for more left shift
    end
    RequestStreamedTextureDict("squaremap", false)
    while not HasStreamedTextureDictLoaded("squaremap") do
        Wait(150)
    end
 
    SetMinimapClipType(0)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
 
    -- Adjust the first value for left shift, careful with aspect ratio
    SetMinimapComponentPosition("minimap", "L", "B", 0.0 + minimapOffset - 0.01, -0.047, 0.1638, 0.183) -- Shifted left
 
    -- Adjust the first value for left shift
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset - 0.01, 0.0, 0.128, 0.20) -- Shifted left
 
    -- Adjust the first value for left shift
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0 + minimapOffset - 0.01, 0.012, 0.250, 0.300) -- Shifted left
 
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    SetMinimapClipType(0)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
 end)
 

 

 
 CreateThread(function()
    while true do
       SetRadarBigmapEnabled(false, false)
       SetRadarZoom(1000)
       Wait(500)
    end
 end)
 
Citizen.CreateThread(function()
    while true do
        Wait(0)

        -- Vanilla HUD off
        HideHudComponentThisFrame(1)
        HideHudComponentThisFrame(2)
        HideHudComponentThisFrame(3)
        HideHudComponentThisFrame(4)
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
        HideHudComponentThisFrame(13)
        HideHudComponentThisFrame(17)
        HideHudComponentThisFrame(20)

        -- Health / Armor pod minimapou
        HideHudComponentThisFrame(21)
        HideHudComponentThisFrame(22)

        -- zachová radar, ale schová vanilla HUD
        HideHudComponentThisFrame(14)
        HideHudComponentThisFrame(19)
    end
end)

-- HUD Settings Command
RegisterCommand('hudsettings', function()
    SendNUIMessage({
        data = 'OPEN_SETTINGS'
    })
    SetNuiFocus(true, true)
end, false)

RegisterKeyMapping('hudsettings', 'Otevrit nastaveni HUDu', 'keyboard', 'F4')

-- NUI callback - zavření settings (vrátí focus zpět do hry)
RegisterNUICallback('closeSettings', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
