local shown = false
local current = 0
local selected = ''
local catalog = {}
local START = vector4(-1050.22, -2963.60, 13.94, 60.0)

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, false)
end

local function destroyCurrent()
    if current ~= 0 and DoesEntityExist(current) then
        SetEntityAsMissionEntity(current, true, true)
        DeleteVehicle(current)
    end
    current = 0
end

local function spawnCar(name)
    if type(name) ~= 'string' or #name < 1 or #name > 64 or not name:match('^[%w_]+$') then
        notify('Invalid model name') return
    end
    local hash = GetHashKey(name)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        notify('Model not found: ' .. name .. ' (check vehicles.meta and restart/reconnect)') return
    end
    RequestModel(hash)
    local deadline = GetGameTimer() + 12000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(50) end
    if not HasModelLoaded(hash) then notify('Model load timed out: ' .. name) return end
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then SetModelAsNoLongerNeeded(hash) return end
    local p = GetEntityCoords(ped)
    local f = GetEntityForwardVector(ped)
    local x, y, z = p.x + f.x * 7.0, p.y + f.y * 7.0, p.z + 0.6
    local heading = GetEntityHeading(ped)
    destroyCurrent()
    local car = CreateVehicle(hash, x, y, z, heading, true, false)
    if car == 0 or not DoesEntityExist(car) then
        notify('CreateVehicle failed: ' .. name)
        SetModelAsNoLongerNeeded(hash) return
    end
    SetEntityAsMissionEntity(car, true, true)
    SetVehicleOnGroundProperly(car)
    SetVehicleEngineOn(car, true, true, false)
    SetVehicleDirtLevel(car, 0.0)
    SetVehicleNumberPlateText(car, 'TEST 001')
    SetPedIntoVehicle(ped, car, -1)
    current = car
    selected = name
    SetModelAsNoLongerNeeded(hash)
    notify('Spawned ' .. name .. '. F6: vehicle tools')
end

local function withCar(fn)
    if current == 0 or not DoesEntityExist(current) then
        current = GetVehiclePedIsIn(PlayerPedId(), false)
    end
    if current == 0 or not DoesEntityExist(current) then notify('Spawn a car first') return end
    fn(current)
end

RegisterNetEvent('rvl:catalog', function(raw)
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then catalog = data end
    if shown then SendNUIMessage({ type = 'catalog', vehicles = catalog }) end
end)

local function menu()
    shown = not shown
    SetNuiFocus(shown, shown)
    if shown then
        TriggerServerEvent('rvl:getCatalog')
        SendNUIMessage({ type = 'open', vehicles = catalog, selected = selected })
    else
        SendNUIMessage({ type = 'close' })
    end
end

RegisterCommand('vehmenu', menu, false)
RegisterKeyMapping('vehmenu', 'Reality Vehicle Lab', 'keyboard', 'F6')
RegisterCommand('v', function(_, args) if args[1] then spawnCar(args[1]:lower()) else menu() end end, false)
RegisterNUICallback('close', function(_, cb) if shown then menu() end cb({ok=true}) end)
RegisterNUICallback('spawn', function(data, cb) spawnCar(tostring(data.model or ''):lower()) cb({ok=true}) end)
RegisterNUICallback('action', function(data, cb)
    local a = tostring(data.action or '')
    if a == 'airport' then
        destroyCurrent()
        local ped = PlayerPedId()
        SetEntityCoords(ped, START.x, START.y, START.z, false, false, false, false)
        SetEntityHeading(ped, START.w)
    elseif a == 'day' then NetworkOverrideClockTime(12, 0, 0)
    elseif a == 'night' then NetworkOverrideClockTime(23, 0, 0)
    elseif a == 'delete' then destroyCurrent()
    else withCar(function(c)
        if a == 'repair' then SetVehicleFixed(c) SetVehicleDeformationFixed(c) SetVehicleEngineHealth(c, 1000.0)
        elseif a == 'clean' then SetVehicleDirtLevel(c, 0.0)
        elseif a == 'flip' then SetVehicleOnGroundProperly(c)
        elseif a == 'extras' then
            local n = tonumber(data.number)
            if n and n >= 0 and n <= 14 then
                n = math.floor(n)
                if DoesExtraExist(c, n) then SetVehicleExtra(c, n, IsVehicleExtraTurnedOn(c, n))
                else notify('Extra ' .. n .. ' not on this car') end
            end
        elseif a == 'livery' then
            local n = tonumber(data.number) or 0
            SetVehicleLivery(c, math.floor(math.max(0, math.min(n, 99))))
        elseif a == 'plate' then
            local p = tostring(data.value or ''):sub(1,8):upper()
            SetVehicleNumberPlateText(c, p)
        elseif a == 'mods' then
            SetVehicleModKit(c, 0)
            for i = 0, 49 do
                if GetNumVehicleMods(c, i) > 0 then SetVehicleMod(c, i, GetNumVehicleMods(c, i)-1, false) end
            end
        elseif a == 'paint' then
            local p = math.floor(math.max(0, math.min(160, tonumber(data.number) or 0)))
            local _, s = GetVehicleColours(c)
            SetVehicleColours(c, p, s)
        end
    end) end
    cb({ok=true})
end)

local function hydraulicDiag(c, apply)
    SetVehicleModKit(c, 0)
    local kit = GetVehicleModKit(c)
    local count = GetNumVehicleMods(c, 38)
    local currentHydro = GetVehicleMod(c, 38)
    local model = GetEntityModel(c)
    local msg = ('Hydraulics | model=%s | modkit=%s | slot38 count=%s | current=%s')
        :format(model, kit, count, currentHydro)
    print('[Reality Vehicle Lab] ' .. msg)
    notify(msg)
    if apply then
        if count > 0 then
            SetVehicleMod(c, 38, 0, false)
            Wait(100)
            local after = GetVehicleMod(c, 38)
            print(('[Reality Vehicle Lab] Applied hydraulic mod slot 38 index 0 | current=%s'):format(after))
            notify(('Hydraulic mod applied | slot38 current=%s'):format(after))
        else
            notify('Hydraulic slot 38 has 0 mods. Check layout/modkit/carcols metadata.')
        end
    end
end

RegisterCommand('checkhydro', function()
    withCar(function(c) hydraulicDiag(c, false) end)
end, false)

RegisterCommand('sethydro', function()
    withCar(function(c) hydraulicDiag(c, true) end)
end, false)

RegisterCommand('moddump', function()
    withCar(function(c)
        SetVehicleModKit(c, 0)
        print(('[Reality Vehicle Lab] MOD DUMP | kit=%s | model=%s'):format(GetVehicleModKit(c), GetEntityModel(c)))
        for i = 0, 49 do
            local count = GetNumVehicleMods(c, i)
            if count > 0 or i == 38 then
                print(('[Reality Vehicle Lab] modType=%02d count=%d current=%d'):format(i, count, GetVehicleMod(c, i)))
            end
        end
        notify('Mod dump printed to F8. Hydraulics = mod type 38.')
    end)
end, false)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(250) end
    Wait(700)
    exports.spawnmanager:setAutoSpawn(false)
    exports.spawnmanager:spawnPlayer({ x=START.x, y=START.y, z=START.z,
        heading=START.w, model='mp_m_freemode_01' }, function()
        TriggerServerEvent('rvl:getCatalog')
        notify('Reality Vehicle Lab ready | F6 tools | /v MODEL | /checkhydro | /sethydro')
    end)
end)
