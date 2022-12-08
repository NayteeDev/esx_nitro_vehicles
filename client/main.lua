local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil

local hasNitroItem = false
local hasWrenchItem = false
local offset = nil
local vehicleCoord = nil
local IsInstallingNitro = false
local nitroUsed = false
local soundofnitro
local sound = false
local exhausts = {}
local installedCars = {}
local installProp = nil
local vehProp = nil
local nitroVehicle

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    ESX.TriggerServerCallback('suku:getInstalledVehicles', function(vehicles)
        installedCars = vehicles
    end)

    RefreshList()
    Citizen.Wait(1000)
end)

RegisterNetEvent('suku:syncInstalledVehicles')
AddEventHandler('suku:syncInstalledVehicles', function(vehicles)
	  installedCars = vehicles
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if DoesEntityExist(GetPlayerPed(-1)) then
            if not IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                if installProp ~= nil then
                    if not hasNitroItem then
                        ESX.TriggerServerCallback('suku:DoesPlayerHaveNitroItem', function(item)
                            if item then
                                hasNitroItem = true
                            end
                        end, 'nitrocannister')
                    end

                    if not hasWrenchItem then
                        ESX.TriggerServerCallback('suku:DoesPlayerHaveNitroItem', function(item)
                            if item then
                                hasWrenchItem = true
                            end
                        end, 'wrench')
                    end
                end
            end
        end
        Citizen.Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local player = GetPlayerPed(-1)
        if DoesEntityExist(player) then
            local textLocation = nil
            if not IsPedInAnyVehicle(player, false) then
                local playerCoord = GetEntityCoords(player)
                local coordA = GetEntityCoords(player, 1)
                local coordB = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 2.0, 0.0)
                local vehicle = GetVehicleInDirection(coordA, coordB)

                if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
                    local x, y, z = table.unpack(GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "engine")))
                    textLocation = vector3(x, y, z)
                    local distanceToEngine = GetDistanceBetweenCoords(coordA, x, y, z, 1)
                    if installProp == nil then
                        installProp = ESX.Game.GetVehicleProperties(vehicle)
                    end
                else
                    if installProp ~= nil then
                        installProp = nil
                    end

                    resetVisual()
                end
            end

            if not IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                if hasNitroItem and installProp ~= nil and not IsPlateInList(installProp.plate) and textLocation ~= nil and not IsInstallingNitro then
                    ESX.Game.Utils.DrawText3D(textLocation, "Use ~r~Nitro~s~ to install nitro", 0.6)
                end
                if hasWrenchItem and installProp ~= nil and IsPlateInList(installProp.plate) and textLocation ~= nil and not IsInstallingNitro then
                    ESX.Game.Utils.DrawText3D(textLocation, "Use ~r~Wrench~s~ to uninstall nitro", 0.6)
                end
            end
        end
    end
end)

RegisterNetEvent('suku:AddInstallNitro')
AddEventHandler('suku:AddInstallNitro', function(source)
    local player = GetPlayerPed(-1)
    if DoesEntityExist(player) then
        local canInstall = true
        local playerCoord = GetEntityCoords(player)
        local coordA = GetEntityCoords(player, 1)
        local coordB = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 2.0, 0.0)
        local vehicle = GetVehicleInDirection(coordA, coordB)

        if installProp ~= nil then
            local x, y, z = table.unpack(GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "engine")))
            local distanceToEngine = GetDistanceBetweenCoords(coordA, x, y, z, 1)
            if distanceToEngine < 2.0 then
                offset = vector3(x, y, z)
                vehicleCoord = GetEntityCoords(vehicle)

                if not IsPlateInList(installProp.plate) then 
                    TriggerEvent('suku:PassOnSequence', vehicle, installProp.plate, "install")
                end
            end
        end
    end
end)

RegisterNetEvent('suku:RemoveUninstallNitro')
AddEventHandler('suku:RemoveUninstallNitro', function(source)
    local player = GetPlayerPed(-1)
    if DoesEntityExist(player) then
        local canInstall = true
        local playerCoord = GetEntityCoords(player)
        local coordA = GetEntityCoords(player, 1)
        local coordB = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 2.0, 0.0)
        local vehicle = GetVehicleInDirection(coordA, coordB)

        if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
            local x, y, z = table.unpack(GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "engine")))
            local distanceToEngine = GetDistanceBetweenCoords(coordA, x, y, z, 1)
            if distanceToEngine < 2.0 then
                offset = vector3(x, y, z)
                vehicleCoord = GetEntityCoords(vehicle)

                if IsPlateInList(installProp.plate) then 
                    TriggerEvent('suku:PassOnSequence', vehicle, installProp.plate, "uninstall")
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsInstallingNitro then
            DisableInput(vehicle)
        end
    end
end)

AddEventHandler('suku:PassOnSequence', function(vehicle, plate, type)
    if IsPlateInList(plate) == true then
        if type == "uninstall" then
            TriggerEvent('suku:UninstallNitroFromVehicle', vehicle, plate)
        end
    else
        if type == "install" then
            TriggerEvent('suku:ImplementNitro', vehicle, plate)
        end
    end
end)

AddEventHandler('suku:ImplementNitro', function(vehicle, plate)
    IsInstallingNitro = true
    FreezeEntityPosition(vehicle, true)
    FreezeEntityPosition(GetPlayerPed(-1), true)
    SetVehicleDoorOpen(vehicle, 4, 0, 0)
    startAnim("mini@repair", "fixing_a_ped")
    TweekNitroTimer('Installing Nitro!')
    Wait(2000)
    PlaySoundFromEntity(-1, "Bar_Unlock_And_Raise", vehicle, "DLC_IND_ROLLERCOASTER_SOUNDS", 0, 0)
    Wait(2000)
    SetAudioFlag("LoadMPData", true)
    PlaySoundFrontend(-1, "Lowrider_Upgrade", "Lowrider_Super_Mod_Garage_Sounds", 1)
    Wait(1000)
    SetVehicleDoorShut(vehicle, 4, 0)
    FreezeEntityPosition(vehicle, false)
    FreezeEntityPosition(GetPlayerPed(-1), false)
    TriggerServerEvent('suku:RemoveNitro', 1)
    TriggerServerEvent('suku:InstallNitro', plate, 100)
    exports['mythic_notify']:SendAlert('inform', 'Nitro has been installed!')
    IsInstallingNitro = false
    RefreshList()
end)

AddEventHandler('suku:UninstallNitroFromVehicle', function(vehicle, plate)
    IsInstallingNitro = true
    FreezeEntityPosition(vehicle, true)
    FreezeEntityPosition(GetPlayerPed(-1), true)
    SetVehicleDoorOpen(vehicle, 4, 0, 0)
    startAnim("mini@repair", "fixing_a_ped")
    TweekNitroTimer('Removing Nitro!')
    Wait(5000)
    SetVehicleDoorShut(vehicle, 4, 0)
    FreezeEntityPosition(vehicle, false)
    FreezeEntityPosition(GetPlayerPed(-1), false)

    local breakchance = math.random(1, 25)
    if breakchance == 13 then
        SetVehicleEngineOn(vehicle, false, false )
        SetVehicleEngineHealth(vehicle, 0)
        SetVehicleUndriveable(vehicle, true)
        exports['mythic_notify']:DoHudText('inform', 'Nitro has been removed \n but the car broke down, \n you cut the wrong tube!')
    else
        exports['mythic_notify']:DoHudText('inform', 'Nitro has been removed!')
    end
    TriggerServerEvent('suku:UninstallNitro', plate)
    IsInstallingNitro = false
    RefreshList()
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)

        local ped = GetPlayerPed(-1)
        local veh = GetVehiclePedIsIn(ped, false)
        local hash = GetEntityModel(veh)

        if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
            if vehProp == nil then
                vehProp = ESX.Game.GetVehicleProperties(veh)
            end

            if nitroVehicle == nil then
                nitroVehicle = GetPlateFromList(vehProp.plate)
            end

            if IsThisModelACar(hash) then
                if IsPlateInList(vehProp.plate) then
                    exhausts = {}

                    for i=1,12 do
                        local exhaust = GetEntityBoneIndexByName(veh, "exhaust_" .. i)
                        if i == 1 and GetEntityBoneIndexByName(veh, "exhaust") ~= -1 then
                            table.insert(exhausts, GetEntityBoneIndexByName(veh, "exhaust"))
                        end
                        if exhaust ~= -1 then
                            table.insert(exhausts, exhaust)
                        end
                    end
                end
            end

            if IsControlPressed(0, Keys["LEFTSHIFT"]) then
                if GetPedInVehicleSeat(veh, -1) == ped then
                    local isVehicleMarked = IsPlateInList(vehProp.plate)
                    if isVehicleMarked then
                        
                        if nitroVehicle.amount > 0 then
                            Citizen.InvokeNative(0xB59E4BD37AE292DB, veh, 5.0)
                            Citizen.InvokeNative(0x93A3996368C94158, veh, 25.0)
                            nitroUsed = true
                            StartScreenEffect("RaceTurbo", 750, false)

                            if sound == false then
                                soundofnitro = PlaySoundFromEntity(GetSoundId(), "Flare", veh, "DLC_HEISTS_BIOLAB_FINALE_SOUNDS", 0, 0)
                                sound = true
                            end
                        end
                    end
                end
            else
                if nitroUsed then
                    nitroUsed = false
                    Citizen.InvokeNative(0xB59E4BD37AE292DB, veh, 1.0)
                    Citizen.InvokeNative(0x93A3996368C94158, veh, 1.0)
        
                    if sound == true then
                        StopSound(soundofnitro)
                        ReleaseSoundId(soundofnitro)
                        sound = false
                    end
                end
            end

            if nitroUsed then
                local ped = GetPlayerPed(-1)
                local veh = GetVehiclePedIsIn(ped, false)
    
                if nitroVehicle.amount > 0 then
                    Wait(Config.consumption)
                    nitroVehicle.amount = nitroVehicle.amount - 1
                    TriggerServerEvent('suku:UpdateNitroAmount', vehProp.plate, 1)
                    if exhausts ~= {} then
                        flame(veh, #exhausts)
                    end
                end
            end
        else
            if vehProp ~= nil then
                vehProp = nil
            end

            if nitroVehicle ~= nil and not IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                nitroVehicle = nil
            end
        end
    end
end)

local uix = 0.01135
local uiy = 0.002

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
            if vehProp ~= nil then
                if IsPlateInList(vehProp.plate) then
                    if nitroVehicle ~= nil then
                        drawRct(0.097 - uix, 0.95 - uiy, 0.046, 0.03, 0, 0, 0, 150)
                        DrawAdvancedText(0.171 - uix, 0.957 - uiy, 0.005, 0.0028, 0.3, "NOS~r~["..tostring(nitroVehicle.amount).."]~s~", 255, 255, 255, 255, 9, 1)
                    end
                end
            end
        end
    end
end)

function IsPlateInList(plate)
    for i = 1, #installedCars, 1 do
        if installedCars[i].plate == plate then
            return true
        end
    end
    return false
end

function GetPlateFromList(plate)
    for i = 1, #installedCars, 1 do
        if installedCars[i].plate == plate then
            return installedCars[i]
        end
    end
    return nil
end

function RefreshList()
    ESX.TriggerServerCallback('suku:getInstalledVehicles', function(vehicles)
        installedCars = {}
        installedCars = vehicles
    end)
end

function TweekNitroTimer(message)
    exports['progressBars']:startUI(5000, message)
end

function resetVisual()
    vehicleCoord = nil
    hasNitroItem = false
    hasWrenchItem = false
    offset = nil
end

function DisableInput(vehicle)
    SetVehicleEngineOn(vehicle, false, false )
    SetVehicleUndriveable(vehicle, true)

    DisableControlAction(0, 24, true) -- Attack
	DisableControlAction(0, 257, true) -- Attack 2
	DisableControlAction(0, 25, true) -- Aim
	DisableControlAction(0, 263, true) -- Melee Attack 1
	DisableControlAction(0, 32, true) -- W
	DisableControlAction(0, 34, true) -- A
	DisableControlAction(0, 31, true) -- S
	DisableControlAction(0, 30, true) -- D

	DisableControlAction(0, 45, true) -- Reload
	DisableControlAction(0, 22, true) -- Jump
	DisableControlAction(0, 44, true) -- Cover
	DisableControlAction(0, 37, true) -- Select Weapon
	DisableControlAction(0, 23, true) -- Also 'enter'?

	DisableControlAction(0, 288,  true) -- Disable phone
	DisableControlAction(0, 289, true) -- Inventory
	DisableControlAction(0, 170, true) -- Animations
	DisableControlAction(0, 167, true) -- Job

	DisableControlAction(0, 73, true) -- Disable clearing animation
	DisableControlAction(2, 199, true) -- Disable pause screen

	DisableControlAction(0, 59, true) -- Disable steering in vehicle
	DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
	DisableControlAction(0, 72, true) -- Disable reversing in vehicle

	DisableControlAction(2, 36, true) -- Disable going stealth

	DisableControlAction(0, 47, true)  -- Disable weapon
	DisableControlAction(0, 264, true) -- Disable melee
	DisableControlAction(0, 257, true) -- Disable melee
	DisableControlAction(0, 140, true) -- Disable melee
	DisableControlAction(0, 141, true) -- Disable melee
	DisableControlAction(0, 142, true) -- Disable melee
	DisableControlAction(0, 143, true) -- Disable melee
	DisableControlAction(0, 75, true)  -- Disable exit vehicle
	DisableControlAction(27, 75, true) -- Disable exit vehicle
end

function flame (veh, count)
    if exhausts then
        if not HasNamedPtfxAssetLoaded("core") then
            RequestNamedPtfxAsset("core")
            while not HasNamedPtfxAssetLoaded("core") do
                Wait(1)
            end
        end
        if count == 1 then
            UseParticleFxAssetNextCall("core")
            fire = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[1], 1.0, 0, 0, 0)
            Wait(0)
            StopParticleFxLooped(fire, false)
        elseif count == 2 then
            UseParticleFxAssetNextCall("core")
            fire = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[1], 1.0, 0, 0, 0)
            UseParticleFxAssetNextCall("core")
            fire2 = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[2], 1.0, 0, 0, 0)
            Wait(0)
            StopParticleFxLooped(fire, false)
            StopParticleFxLooped(fire2, false)
        elseif count == 3 then
            UseParticleFxAssetNextCall("core")
            fire = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[1], 1.0, 0, 0, 0)
            UseParticleFxAssetNextCall("core")
            fire2 = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[2], 1.0, 0, 0, 0)
            UseParticleFxAssetNextCall("core")
            fire3 = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[3], 1.0, 0, 0, 0)
            Wait(0)
            StopParticleFxLooped(fire, false)
            StopParticleFxLooped(fire2, false)
            StopParticleFxLooped(fire3, false)
        elseif count == 4 then
            UseParticleFxAssetNextCall("core")
            fire = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[1], 1.0, 0, 0, 0)
            UseParticleFxAssetNextCall("core")
            fire2 = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[2], 1.0, 0, 0, 0)
            UseParticleFxAssetNextCall("core")
            fire3 = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[3], 1.0, 0, 0, 0)
            UseParticleFxAssetNextCall("core")
            fire4 = StartParticleFxLoopedOnEntityBone_2("veh_backfire", veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, exhausts[4], 1.0, 0, 0, 0)
            Wait(0)
            StopParticleFxLooped(fire, false)
            StopParticleFxLooped(fire2, false)
            StopParticleFxLooped(fire3, false)
            StopParticleFxLooped(fire4, false)
        end
    end
end

function GetVehicleInDirection(coordFrom, coordTo)
    local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
    local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

function drawRct(x, y, width, height, r, g, b, a)
	DrawRect(x, y, width, height, r, g, b, a)
end

function DrawAdvancedText(x,y ,w,h,sc, text, r,g,b,a,font,jus)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(sc, sc)
    N_0x4e096588b13ffeca(jus)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - 0.1+w, y - 0.02+h)
end

function startAnim(lib, anim)
	ESX.Streaming.RequestAnimDict(lib, function()
		TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, 5000, 0, 0, false, false, false)
	end)
end