local opened, opening, generation = false, false, 0
local previewEntity, camera, lockedPed, stableIndex, latest, pendingCall
local pending, sequence, rides, blips, vendors = {}, 0, {}, {}, {}
local leadPrompt
local leadRequest
local dismissPrompt
local prompt, promptGroup = nil, GetRandomIntInRange(0, 0xffffff)
local characterEpoch = 0
local menuEpoch = 0
local assetsReady = false
local previewModel, previewKind, previewGear = nil, nil, {}
local previewDrafts = {}
local rotation
local rotationWorker = 0

local function sendUI(message)
    if message.action == 'open' or message.action == 'loading' then
        message.locale = StableLocale.code
        message.messages = StableLocale.messages
    end
    if message.message then
        message.message = StableLocale.text(message.message)
    end
    SendNUIMessage(message)
end

RegisterNUICallback('locale', function(_, cb)
    cb({ locale = StableLocale.code, messages = StableLocale.messages })
end)

local function tip(message)
    sendUI({ action = 'error', message = message })
end

local function rpc(request, done)
    sequence = sequence + 1
    local id = sequence
    pending[id] = done
    TriggerServerEvent('330_stables:request', id, request)
    SetTimeout(15000, function()
        if pending[id] then
            local fn = pending[id]
            pending[id] = nil
            fn({ ok = false, error = 'The stable did not respond. Please try again.' })
        end
    end)
end

RegisterNetEvent('330_stables:response', function(id, result)
    local fn = pending[id]
    if not fn then
        return
    end
    pending[id] = nil
    fn(type(result) == 'table' and result or { ok = false, error = 'Invalid stable response.' })
end)

local function draftAnimals(vehicle)
    local result, seen = {}, {}
    for index = 0, 5 do
        local ped = Citizen.InvokeNative(0xA8BA0BAE0173457B, vehicle, index, Citizen.ResultAsInteger())
        if ped and ped ~= 0 and not seen[ped] and DoesEntityExist(ped) then
            result[#result + 1] = ped
            seen[ped] = true
        end
    end
    return result
end

local function deleteDraftAnimals(vehicle)
    for _, ped in ipairs(draftAnimals(vehicle)) do
        DeleteEntity(ped)
    end
end

local function removePreview()
    rotation = nil
    rotationWorker = rotationWorker + 1
    for _, ped in ipairs(previewDrafts) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    previewDrafts = {}
    if previewEntity and DoesEntityExist(previewEntity) then
        if previewKind == 'cart' then
            deleteDraftAnimals(previewEntity)
        end
        DeleteEntity(previewEntity)
    end
    previewEntity = nil
    previewModel, previewKind, previewGear = nil, nil, {}
end

local function clearRide(kind)
    local ride = rides[kind]
    if ride then
        StableInteractions.stop(ride.entity)
        if ride.blip then
            RemoveBlip(ride.blip)
        end
        if ride.entity and DoesEntityExist(ride.entity) then
            if kind == 'cart' then
                deleteDraftAnimals(ride.entity)
            end
            DeleteEntity(ride.entity)
        end
        rides[kind] = nil
    end
end

local function close(immediate)
    leadRequest = nil
    StableInteractions.stop()
    menuEpoch = menuEpoch + 1
    opened = false
    opening = false
    generation = generation + 1
    SetNuiFocus(false, false)
    if camera then
        RenderScriptCams(false, not immediate, immediate and 0 or 320, true, true)
        DestroyCam(camera, false)
        camera = nil
    end
    removePreview()
    if lockedPed and DoesEntityExist(lockedPed) then
        FreezeEntityPosition(lockedPed, false)
    end
    StableReading.stop()
    lockedPed = nil
    stableIndex = nil
    sendUI({ action = 'close' })
end

local function applyGear(entity, gear)
    for _, hash in pairs(gear or {}) do
        Citizen.InvokeNative(0xD3A7B003ED343FD9, entity, tonumber(hash), true, true, true)
    end
    Citizen.InvokeNative(0xCC8CA3E88256E58F, entity, 0, 1, 1, 1, 0)
end

local function updatePreviewGear(entity, gear)
    local changed = false
    for family, hash in pairs(previewGear) do
        if tonumber(gear[family]) ~= tonumber(hash) then
            Citizen.InvokeNative(0x0D7FFA1B2F69ED82, entity, tonumber(hash), 0, false)
            changed = true
        end
    end
    for family, hash in pairs(gear) do
        if tonumber(previewGear[family]) ~= tonumber(hash) then
            Citizen.InvokeNative(0xD3A7B003ED343FD9, entity, tonumber(hash), true, true, true)
            changed = true
        end
    end
    if changed then
        Citizen.InvokeNative(0xCC8CA3E88256E58F, entity, 0, 1, 1, 1, 0)
    end
    previewGear = {}
    for family, hash in pairs(gear) do
        previewGear[family] = hash
    end
end

local function loadModel(model, valid)
    local hash = GetHashKey(model)
    if not IsModelValid(hash) then
        return
    end
    RequestModel(hash, false)
    local deadline = GetGameTimer() + Config.PreviewTimeout
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do
        if not valid() then
            StablePreload.release(hash)
            return
        end
        Wait(20)
    end
    if not valid() or not HasModelLoaded(hash) then
        StablePreload.release(hash)
        return
    end
    return hash
end

local function cameraFor(stable, kind, entity)
    local options = Config.PreviewCamera or {}
    local wagonSpot = kind == 'cart' or options.HorsesUseWagonSpot
    local p = wagonSpot and stable.CamCart or stable.CamHorse
    local target = GetEntityCoords(entity)
    if not camera then
        camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end
    SetCamCoord(camera, p[1], p[2], p[3])
    local dx, dy = target.x - p[1], target.y - p[2]
    local length = math.max(0.01, math.sqrt(dx * dx + dy * dy))
    local offset = kind == 'cart' and 1.0 or 0.65
    PointCamAtCoord(
        camera,
        target.x - dy / length * offset,
        target.y + dx / length * offset,
        target.z + (kind == 'cart' and 1.0 or 0.85)
    )
    SetCamFov(camera, kind == 'cart' and (options.WagonFov or 60.0) or (options.HorseFov or 56.0))
    RenderScriptCams(true, true, 420, true, true)
end

local function selectPreview(data)
    if not opened or not latest then
        return
    end
    local model, kind, gear = data.model, data.kind or 'horse', {}
    if data.id then
        local found
        for _, row in ipairs(latest.rides or {}) do
            if row.id == data.id then
                found = row
                break
            end
        end
        if not found then
            for _, row in ipairs(latest.offers or {}) do
                if row.id == data.id then
                    found = row
                    break
                end
            end
        end
        if not found then
            return
        end
        model = found.modelname
        kind = found.type
        for k, v in pairs(found.gear or {}) do
            gear[k] = v
        end
        if data.family and data.hash then
            local item = StableCatalog.equipment(data.family, data.hash)
            if not item then
                return
            end
            gear[item.family] = item.hash
        end
    elseif not StableCatalog.price(stableIndex, kind, model) then
        return
    end
    generation = generation + 1
    local ticket = generation
    local stable = Config.Stables[stableIndex]
    if
        previewEntity
        and DoesEntityExist(previewEntity)
        and previewKind == kind
        and previewModel == model:lower()
    then
        if kind == 'horse' then
            updatePreviewGear(previewEntity, gear)
        end
        return
    end
    CreateThread(function()
        local hash = loadModel(model, function()
            return opened and generation == ticket
        end)
        if not hash then
            if opened and generation == ticket then
                tip('This model could not be loaded. Choose another variant.')
            end
            return
        end
        local wagonSpot = kind == 'cart' or (Config.PreviewCamera or {}).HorsesUseWagonSpot
        local p = wagonSpot and stable.SpawnCart or stable.SpawnHorse
        RequestCollisionAtCoord(p[1], p[2], p[3])
        local entity
        if kind == 'cart' then
            entity = CreateVehicle(hash, p[1], p[2], p[3], p[4], false, true, false, true)
        else
            entity = CreatePed(hash, p[1], p[2], p[3], p[4], false, true, true, true)
        end
        StablePreload.release(hash)
        if not entity or entity == 0 then
            tip('This model could not be created.')
            return
        end
        SetEntityVisible(entity, false)
        SetEntityAsMissionEntity(entity, true, true)
        SetEntityInvincible(entity, true)
        FreezeEntityPosition(entity, true)
        if kind == 'horse' then
            SetBlockingOfNonTemporaryEvents(entity, true)
            Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
            applyGear(entity, gear)
        end
        if kind == 'cart' then
            Citizen.InvokeNative(0x87344305778E5415, entity, true)
        end
        Wait(120)
        local animals = kind == 'cart' and draftAnimals(entity) or {}
        if not opened or generation ~= ticket then
            for _, ped in ipairs(animals) do
                DeleteEntity(ped)
            end
            DeleteEntity(entity)
            return
        end
        removePreview()
        previewEntity = entity
        previewDrafts = animals
        for _, ped in ipairs(animals) do
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
        end
        previewModel, previewKind = model:lower(), kind
        for family, hash in pairs(gear) do
            previewGear[family] = hash
        end
        SetEntityVisible(entity, true)
        cameraFor(stable, kind, entity)
    end)
end

local function updateData(data)
    if not data then
        return
    end
    StablePreload.include(data.rides)
    for kind, ride in pairs(rides) do
        local owned
        for _, row in ipairs(data.rides or {}) do
            if row.id == ride.id then
                owned = row
                break
            end
        end
        if
            not owned
            or tonumber(owned.isDefault) ~= 1
            or (type(owned.status) == 'table' and owned.status.transferTarget)
        then
            clearRide(kind)
        elseif kind == 'horse' and DoesEntityExist(ride.entity) then
            -- Recreate on next call if equipment changed; previews always use saved gear.
            if json.encode(owned.gear or {}) ~= ride.gear then
                clearRide(kind)
            end
        end
    end
    latest = data
end

local function nearby()
    local p = GetEntityCoords(PlayerPedId())
    for index, stable in ipairs(Config.Stables) do
        local q = stable.EnterStable
        if (p.x - q[1]) ^ 2 + (p.y - q[2]) ^ 2 + (p.z - q[3]) ^ 2 <= (q[4] or 2.5) ^ 2 then
            return index
        end
    end
end

local function availableModels(groups)
    local result = {}
    for _, group in ipairs(groups or {}) do
        local coats = {}
        for _, coat in ipairs(group.coats or {}) do
            if not StablePreload.isFailed(coat.model) then
                coats[#coats + 1] = coat
            end
        end
        if #coats > 0 then
            group.coats = coats
            result[#result + 1] = group
        end
    end
    return result
end

local function open(index)
    if opened then
        close(false)
        return
    end
    if opening or not index or IsNuiFocused() or IsEntityDead(PlayerPedId()) then
        return
    end
    StableInteractions.stop()
    StablePreload.prepare(index)
    opening = true
    generation = generation + 1
    local ticket = generation
    assetsReady = false
    lockedPed = PlayerPedId()
    FreezeEntityPosition(lockedPed, true)
    SetNuiFocus(true, true)
    StablePreload.requestAll()
    local progress = StablePreload.status()
    sendUI({
        action = 'loading',
        ticket = ticket,
        location = Config.Stables[index].Name,
        loaded = progress.loaded,
        total = progress.total,
    })
    rpc({ action = 'open', stable = index }, function(result)
        if generation ~= ticket then
            return
        end
        if not result.ok then
            close(true)
            tip(result.error)
            return
        end
        if nearby() ~= index or IsEntityDead(PlayerPedId()) then
            close(true)
            return
        end
        updateData(result.data)
        StablePreload.include(result.data.offers)
        StablePreload.requestAll()
        CreateThread(function()
            local deadline = GetGameTimer() + (Config.EntryTimeoutMs or 20000)
            while opening and generation == ticket do
                StablePreload.poll()
                local status = StablePreload.status()
                if status.pending == 0 and assetsReady then
                    if status.total > 0 and status.loaded == 0 then
                        close(true)
                        tip('No stable models could load. Check the client console for details.')
                        return
                    end
                    result.data.horses = availableModels(result.data.horses)
                    result.data.wagons = availableModels(result.data.wagons)
                    opening = false
                    menuEpoch = menuEpoch + 1
                    stableIndex = index
                    opened = true
                    local reading = Config.MenuReading or {}
                    if
                        reading.Enabled
                        and not IsPedOnMount(PlayerPedId())
                        and not (
                            type(IsPedInAnyVehicle) == 'function' and IsPedInAnyVehicle(PlayerPedId(), false)
                        )
                    then
                        StableReading.start(PlayerPedId(), reading)
                    end
                    sendUI({ action = 'open', data = result.data })
                    return
                end
                if GetGameTimer() >= deadline then
                    close(true)
                    tip('Stable loading timed out. Please try again.')
                    return
                end
                sendUI({ action = 'loadingProgress', loaded = status.loaded, total = status.total })
                Wait(100)
            end
        end)
    end)
end

RegisterNUICallback('assetsReady', function(data, cb)
    if opening and tonumber(data.ticket) == generation then
        assetsReady = true
    end
    cb({ ok = true })
end)

local function spawnRide(kind)
    if pendingCall or IsEntityDead(PlayerPedId()) then
        return
    end
    local present = rides[kind]
    if present and DoesEntityExist(present.entity) and not IsEntityDead(present.entity) then
        if kind == 'cart' then
            tip('Your wagon is already called out.')
        else
            present.fleeing = false
            local p, q = GetEntityCoords(PlayerPedId()), GetEntityCoords(present.entity)
            if (p.x - q.x) ^ 2 + (p.y - q.y) ^ 2 + (p.z - q.z) ^ 2 > 16 then
                TaskGoToEntity(present.entity, PlayerPedId(), -1, 2.0, 3.0, 0, 0)
            else
                tip('Your horse is already beside you.')
            end
        end
        return
    end
    local session = characterEpoch
    local callToken = {}
    pendingCall = callToken
    local function finish()
        if pendingCall == callToken then
            pendingCall = nil
        end
    end
    rpc({ action = 'spawn', kind = kind }, function(result)
        if session ~= characterEpoch or pendingCall ~= callToken then
            return
        end
        if not result.ok then
            finish()
            tip(result.error)
            return
        end
        if kind == 'horse' and Config.WhistleOnCall ~= false then
            -- VORP Character owns pitch, clarity and style on this ped.
            TaskWhistleAnim(PlayerPedId(), GetHashKey('WHISTLEHORSELONG'), GetHashKey('unspecified'))
        end
        local row = result.spawn
        local old = rides[kind]
        if old and old.id == row.id and DoesEntityExist(old.entity) and not IsEntityDead(old.entity) then
            if kind == 'horse' then
                old.fleeing = false
                TaskGoToEntity(old.entity, PlayerPedId(), -1, 2.0, 3.0, 0, 0)
            end
            finish()
            return
        end
        CreateThread(function()
            local token = generation
            local hash = loadModel(row.modelname, function()
                return token == generation
                    and session == characterEpoch
                    and pendingCall == callToken
                    and not IsEntityDead(PlayerPedId())
            end)
            if not hash then
                finish()
                if session == characterEpoch then
                    tip('Your ride could not be loaded.')
                end
                return
            end
            local function validCall()
                return token == generation
                    and session == characterEpoch
                    and pendingCall == callToken
                    and not IsEntityDead(PlayerPedId())
            end
            local p, heading = StableSpawn.find(kind, hash, validCall)
            if not p then
                StablePreload.release(hash)
                finish()
                if session == characterEpoch then
                    tip('No clear space nearby. Move to an open road and try again.')
                end
                return
            end
            clearRide(kind)
            local entity
            if kind == 'horse' then
                entity = CreatePed(hash, p.x, p.y, p.z, heading, true, true, false, false)
            else
                entity = CreateVehicle(hash, p.x, p.y, p.z, heading, true, true, false, true)
            end
            StablePreload.release(hash)
            if not entity or entity == 0 then
                finish()
                tip('Your ride could not be created.')
                return
            end
            SetEntityAsMissionEntity(entity, true, true)
            SetEntityInvincible(entity, true)
            FreezeEntityPosition(entity, true)
            local protectedEntity = entity
            local protectedDrafts = {}
            if kind == 'cart' then
                SetTimeout(150, function()
                    local ride = rides.cart
                    if not ride or ride.entity ~= protectedEntity then
                        return
                    end
                    for _, animal in ipairs(draftAnimals(protectedEntity)) do
                        SetEntityInvincible(animal, true)
                        FreezeEntityPosition(animal, true)
                        protectedDrafts[#protectedDrafts + 1] = animal
                    end
                end)
            end
            SetTimeout(1500, function()
                local ride = rides[kind]
                if ride and ride.entity == protectedEntity and DoesEntityExist(protectedEntity) then
                    FreezeEntityPosition(protectedEntity, false)
                    SetEntityInvincible(protectedEntity, false)
                    for _, animal in ipairs(protectedDrafts) do
                        if DoesEntityExist(animal) then
                            FreezeEntityPosition(animal, false)
                            SetEntityInvincible(animal, false)
                        end
                    end
                end
            end)
            if kind == 'cart' then
                Citizen.InvokeNative(0x87344305778E5415, entity, true)
            end
            if kind == 'horse' then
                Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
                applyGear(entity, row.gear)
                Citizen.InvokeNative(0xADB3F206518799E8, entity, GetHashKey('PLAYER'))
                Citizen.InvokeNative(0x931B241409216C1F, PlayerPedId(), entity, false)
                Citizen.InvokeNative(0xAEB97D84CDF3C00B, entity, false)
                Citizen.InvokeNative(0xB8B6430EAD2D2437, entity, GetHashKey('PLAYER_HORSE'))
                Citizen.InvokeNative(0xDF93973251FB2CA5, PlayerId(), true)
                Citizen.InvokeNative(0x4A48B6E03BABB4AC, entity, row.name)
                TaskGoToEntity(entity, PlayerPedId(), -1, 2.0, 3.0, 0, 0)
            end
            local blip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, entity)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, row.name)
            rides[kind] = {
                id = row.id,
                entity = entity,
                blip = blip,
                gear = json.encode(row.gear or {}),
                name = row.name,
            }
            if GetResourceState('lab_inventory') == 'started' then
                exports.lab_inventory:RegisterProviderEntity(
                    'vorp_stables',
                    kind == 'horse' and 'horse' or 'wagon',
                    row.id,
                    entity
                )
            end
            finish()
        end)
    end)
end

local function fleeHorse()
    local ride = rides.horse
    if opened or opening or not ride or ride.fleeing or not DoesEntityExist(ride.entity) then
        return
    end
    if IsPedOnMount(PlayerPedId()) and GetMount(PlayerPedId()) == ride.entity then
        tip('Dismount before sending your horse away.')
        return
    end
    local rider = GetRiderOfMount(ride.entity, true)
    if rider and rider ~= 0 and IsPedAPlayer(rider) then
        tip('Your horse is being ridden by another player.')
        return
    end
    ride.fleeing = true
    ClearPedTasks(ride.entity)
    Citizen.InvokeNative(0xFD45175A6DFD7CE9, ride.entity, PlayerPedId(), 3, 0, -1.0, -1, 0)
    SetTimeout(Config.FleeDespawnMs or 10000, function()
        if rides.horse == ride and ride.fleeing then
            clearRide('horse')
        end
    end)
end

local function checkWagon(id)
    local ride = rides.cart
    if not ride or (id and ride.id ~= id) or not DoesEntityExist(ride.entity) then
        return false, 'This wagon is not currently called out.'
    end
    if IsEntityDead(PlayerPedId()) or IsEntityDead(ride.entity) then
        return false, 'You cannot store this wagon right now.'
    end
    local p, q = GetEntityCoords(PlayerPedId()), GetEntityCoords(ride.entity)
    if (p.x - q.x) ^ 2 + (p.y - q.y) ^ 2 + (p.z - q.z) ^ 2 > (Config.InteractionDistance or 18.0) ^ 2 then
        return false, 'Move closer to your wagon.'
    end
    if not NetworkHasControlOfEntity(ride.entity) then
        return false, 'Your wagon is not ready. Try again in a moment.'
    end
    if GetEntitySpeed(ride.entity) > 1.0 then
        return false, 'Stop your wagon before dismissing it.'
    end
    for _, animal in ipairs(draftAnimals(ride.entity)) do
        if GetRiderOfMount(animal) ~= 0 then
            return false, 'Everyone must dismount the draft horses first.'
        end
    end
    for seat = -1, 7 do
        local ped = GetPedInVehicleSeat(ride.entity, seat)
        if ped and ped ~= 0 then
            return false, 'Everyone must leave the wagon before storing it.'
        end
    end
    return true
end

local dismissPending = false
local function storeWagon(id, done)
    done = done
        or function(ok, message)
            tip(ok and 'Wagon stored. Use J to call it again.' or message)
        end
    local ok, message = checkWagon(id)
    if not ok then
        done(false, message)
        return
    end
    if dismissPending then
        done(false, 'Please wait for your wagon.')
        return
    end
    dismissPending = true
    local ride, session = rides.cart, characterEpoch
    rpc(
        { action = 'dismiss', id = ride.id, netId = NetworkGetNetworkIdFromEntity(ride.entity) },
        function(result)
            dismissPending = false
            if session ~= characterEpoch or rides.cart ~= ride then
                done(false, 'Your wagon changed.')
                return
            end
            if not result.ok then
                done(false, result.error)
                return
            end
            local clear, reason = checkWagon(ride.id)
            if clear then
                clearRide('cart')
            end
            done(clear, reason)
        end
    )
end

local function leadRide(kind, ride, animal)
    if leadRequest then
        leadRequest = nil
        return
    end
    if StableInteractions.isLeading(ride.entity) then
        StableInteractions.stop()
        return
    end
    if opened or opening then
        return
    end
    if kind == 'cart' then
        local ok, message = checkWagon(ride.id)
        if not ok then
            tip(message)
            return
        end
    end
    local request = { ride = ride }
    leadRequest = request
    local session = characterEpoch
    rpc(
        { action = 'lead', id = ride.id, netId = NetworkGetNetworkIdFromEntity(ride.entity) },
        function(result)
            if leadRequest ~= request then
                return
            end
            leadRequest = nil
            if session ~= characterEpoch or rides[kind] ~= ride or opened or opening then
                return
            end
            if not result.ok then
                tip(result.error)
                return
            end
            if kind == 'cart' then
                local ok, message = checkWagon(ride.id)
                if not ok then
                    tip(message)
                    return
                end
            end
            StableInteractions.lead(ride.entity, animal, function(ok, message)
                if not ok then
                    tip(message)
                end
            end)
        end
    )
end

RegisterCommand('dismisswagon', function()
    storeWagon()
end, false)

RegisterCommand('fleehorse', fleeHorse, false)

RegisterCommand(Config.Command, function()
    local index = nearby()
    if index then
        open(index)
    else
        tip('Visit a stable and press G.')
    end
end, false)

RegisterCommand('callhorse', function()
    if not opened then
        spawnRide('horse')
    end
end, false)

RegisterCommand('callwagon', function()
    if not opened then
        spawnRide('cart')
    end
end, false)

RegisterNUICallback('select', function(data, cb)
    selectPreview(data)
    cb({ ok = true })
end)

RegisterNUICallback('rotate', function(data, cb)
    if previewEntity and DoesEntityExist(previewEntity) then
        local entity = previewEntity
        local delta = math.max(-30, math.min(30, tonumber(data.delta) or 15))
        local current = GetEntityHeading(entity)
        local desired = (rotation and rotation.entity == entity and rotation.target or current) + delta
        local difference = (desired - current + 180) % 360 - 180
        local running = rotation ~= nil
        rotation = { entity = entity, start = current, target = current + difference, time = GetGameTimer() }
        if not running then
            rotationWorker = rotationWorker + 1
            local worker = rotationWorker
            CreateThread(function()
                while
                    rotation
                    and rotationWorker == worker
                    and previewEntity == rotation.entity
                    and DoesEntityExist(rotation.entity)
                do
                    local r = rotation
                    local t = math.min(1, (GetGameTimer() - r.time) / 240)
                    local heading = r.start + (r.target - r.start) * (1 - (1 - t) ^ 3)
                    local old = GetEntityHeading(r.entity)
                    local origin = GetEntityCoords(r.entity)
                    local angle = math.rad(heading - old)
                    local animals = {}
                    for _, ped in ipairs(previewDrafts) do
                        if DoesEntityExist(ped) then
                            animals[#animals + 1] = {
                                ped = ped,
                                position = GetEntityCoords(ped),
                                heading = GetEntityHeading(ped),
                            }
                        end
                    end
                    SetEntityHeading(r.entity, heading)
                    for _, item in ipairs(animals) do
                        local x, y = item.position.x - origin.x, item.position.y - origin.y
                        SetEntityCoordsNoOffset(
                            item.ped,
                            origin.x + x * math.cos(angle) - y * math.sin(angle),
                            origin.y + x * math.sin(angle) + y * math.cos(angle),
                            item.position.z,
                            false,
                            false,
                            false
                        )
                        SetEntityHeading(item.ped, item.heading + heading - old)
                    end
                    if t >= 1 then
                        rotation = nil
                        break
                    end
                    Wait(0)
                end
            end)
        end
    end
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    close(false)
    cb({ ok = true })
end)

RegisterNUICallback('request', function(data, cb)
    if not opened or type(data) ~= 'table' then
        cb({ ok = false, error = 'Reopen the stable.' })
        return
    end
    if data.action == 'store' then
        storeWagon(tonumber(data.id), function(ok, message)
            cb({ ok = ok, data = latest, message = ok and 'Wagon stored.' or nil, error = message })
        end)
        return
    end
    local session, menu = characterEpoch, menuEpoch
    if data.action == 'call' then
        rpc({ action = 'active', stable = stableIndex, id = data.id }, function(result)
            if session ~= characterEpoch or menu ~= menuEpoch then
                cb({ ok = false, error = 'Your stable session changed.' })
                return
            end
            cb(result)
            if result.ok then
                local kind = data.kind
                updateData(result.data)
                close(false)
                local closedMenu = menuEpoch
                SetTimeout(200, function()
                    if session == characterEpoch and closedMenu == menuEpoch then
                        spawnRide(kind)
                    end
                end)
            end
        end)
        return
    end
    data.stable = stableIndex
    rpc(data, function(result)
        if session ~= characterEpoch or menu ~= menuEpoch then
            cb({ ok = false, error = 'Your stable session changed.' })
            return
        end
        if result.ok and result.data then
            updateData(result.data)
        end
        cb(result)
    end)
end)

RegisterNetEvent('330_stables:changed', function()
    SetTimeout(250, function()
        if opened or opening then
            local session, menu = characterEpoch, menuEpoch
            rpc({ action = 'open', stable = stableIndex }, function(result)
                if opened and result.ok and session == characterEpoch and menu == menuEpoch then
                    updateData(result.data)
                    sendUI({ action = 'refresh', data = result.data })
                end
            end)
        elseif next(rides) then
            local session = characterEpoch
            rpc({ action = 'refresh' }, function(result)
                if result.ok and session == characterEpoch then
                    updateData(result.data)
                end
            end)
        end
    end)
end)

RegisterNetEvent('vorp:SelectedCharacter', function()
    characterEpoch = characterEpoch + 1
    pendingCall = nil
    StablePreload.clear()
    close(true)
    clearRide('horse')
    clearRide('cart')
    latest = nil
end)

CreateThread(function()
    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, Config.OpenKey)
    UiPromptSetText(prompt, VarString(10, 'LITERAL_STRING', StableLocale.text('Browse stable')))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetStandardMode(prompt, true)
    UiPromptSetGroup(prompt, promptGroup, 0)
    UiPromptRegisterEnd(prompt)
    dismissPrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(dismissPrompt, Keys.F)
    UiPromptSetText(dismissPrompt, VarString(10, 'LITERAL_STRING', StableLocale.text('Dismiss')))
    UiPromptSetEnabled(dismissPrompt, false)
    UiPromptSetVisible(dismissPrompt, false)
    UiPromptSetStandardMode(dismissPrompt, true)
    UiPromptRegisterEnd(dismissPrompt)
    leadPrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(leadPrompt, Keys.E)
    UiPromptSetText(leadPrompt, VarString(10, 'LITERAL_STRING', StableLocale.text('Lead')))
    UiPromptSetEnabled(leadPrompt, false)
    UiPromptSetVisible(leadPrompt, false)
    UiPromptSetStandardMode(leadPrompt, true)
    UiPromptRegisterEnd(leadPrompt)
    local interactionGroup = GetRandomIntInRange(0, 0xffffff)
    local draftScanAt, draftTargets = 0, {}
    while true do
        local index = not opened and nearby()
        UiPromptSetEnabled(dismissPrompt, false)
        UiPromptSetVisible(dismissPrompt, false)
        UiPromptSetEnabled(leadPrompt, false)
        UiPromptSetVisible(leadPrompt, false)
        if opened then
            if type(HideHudAndRadarThisFrame) == 'function' then
                HideHudAndRadarThisFrame()
            end
            DisableControlAction(0, 0x07CE1E61, true)
            DisableControlAction(0, 0xF84FA74F, true)
            if lockedPed ~= PlayerPedId() or IsEntityDead(PlayerPedId()) then
                close(true)
            end
        elseif LocalPlayer.state.IsInSession then
            if index and not opening and not IsNuiFocused() and not IsEntityDead(PlayerPedId()) then
                UiPromptSetActiveGroupThisFrame(
                    promptGroup,
                    VarString(10, 'LITERAL_STRING', StableLocale.stableName(Config.Stables[index].Name)),
                    0,
                    0,
                    0,
                    0
                )
                if UiPromptHasStandardModeCompleted(prompt, 0) then
                    open(index)
                end
            end
            if not IsNuiFocused() then
                -- Handle the whistle key ourselves so the native control cannot play it twice.
                DisableControlAction(0, Config.CallHorseKey, true)
                if IsDisabledControlJustPressed(0, Config.CallHorseKey) then
                    spawnRide('horse')
                end
                if IsControlJustPressed(0, Config.CallCartKey) then
                    spawnRide('cart')
                end
                local targeting, target = GetPlayerTargetEntity(PlayerId())
                local focusedKind, focusedRide, focusedAnimal
                local wagon = rides.cart
                if
                    targeting
                    and wagon
                    and DoesEntityExist(wagon.entity)
                    and not IsEntityDead(PlayerPedId())
                then
                    local p, q = GetEntityCoords(PlayerPedId()), GetEntityCoords(wagon.entity)
                    if
                        (p.x - q.x) ^ 2 + (p.y - q.y) ^ 2 + (p.z - q.z) ^ 2
                        <= (Config.InteractionDistance or 18.0) ^ 2
                    then
                        if GetGameTimer() >= draftScanAt then
                            draftTargets = draftAnimals(wagon.entity)
                            draftScanAt = GetGameTimer() + 500
                        end
                        if StableInteractions.wagonTarget(wagon, target, draftTargets) then
                            focusedKind, focusedRide = 'cart', wagon
                            focusedAnimal = target ~= wagon.entity and target or draftTargets[1]
                        end
                    end
                end
                local ownHorse = rides.horse
                if targeting and ownHorse and target == ownHorse.entity and DoesEntityExist(target) then
                    focusedKind, focusedRide, focusedAnimal = 'horse', ownHorse, target
                end
                if focusedRide then
                    local group = Citizen.InvokeNative(0xB796970BD125FCE8, target, Citizen.ResultAsInteger())
                    if not group or group == 0 then
                        group = interactionGroup
                    end
                    UiPromptSetActiveGroupThisFrame(
                        group,
                        VarString(
                            10,
                            'LITERAL_STRING',
                            focusedRide.name or (focusedKind == 'cart' and 'Wagon' or 'Horse')
                        ),
                        0,
                        0,
                        0,
                        0
                    )
                    if focusedKind == 'cart' then
                        UiPromptSetGroup(dismissPrompt, group, 0)
                        UiPromptSetEnabled(dismissPrompt, true)
                        UiPromptSetVisible(dismissPrompt, true)
                        if IsControlJustPressed(0, Keys.F) or IsDisabledControlJustPressed(0, Keys.F) then
                            storeWagon(focusedRide.id)
                        end
                    end
                    if
                        Config.EnableLeading
                        and focusedAnimal
                        and (focusedKind ~= 'cart' or Config.EnableDraftLeading)
                    then
                        UiPromptSetGroup(leadPrompt, group, 0)
                        UiPromptSetText(
                            leadPrompt,
                            VarString(
                                10,
                                'LITERAL_STRING',
                                StableLocale.text(
                                    (
                                        StableInteractions.isLeading(focusedRide.entity)
                                        or (leadRequest and leadRequest.ride == focusedRide)
                                    )
                                            and 'Stop leading'
                                        or 'Lead'
                                )
                            )
                        )
                        UiPromptSetEnabled(leadPrompt, true)
                        UiPromptSetVisible(leadPrompt, true)
                        if IsControlJustPressed(0, Keys.E) or IsDisabledControlJustPressed(0, Keys.E) then
                            leadRide(focusedKind, focusedRide, focusedAnimal)
                        end
                    end
                end
                local horse = rides.horse
                if horse and DoesEntityExist(horse.entity) then
                    local targeting, target = GetPlayerTargetEntity(PlayerId())
                    if
                        targeting
                        and target == horse.entity
                        and IsControlJustPressed(0, Keys.HorseCommandFlee)
                    then
                        fleeHorse()
                    end
                end
                for kind, ride in pairs(rides) do
                    if DoesEntityExist(ride.entity) then
                        local p, q = GetEntityCoords(PlayerPedId()), GetEntityCoords(ride.entity)
                        if
                            (p.x - q.x) ^ 2 + (p.y - q.y) ^ 2 + (p.z - q.z) ^ 2 < 16
                            and IsControlJustPressed(
                                0,
                                kind == 'horse' and GetHashKey('INPUT_OPEN_SATCHEL_HORSE_MENU') or Keys.U
                            )
                        then
                            rpc({
                                action = 'inventory',
                                id = ride.id,
                                netId = NetworkGetNetworkIdFromEntity(ride.entity),
                            }, function(result)
                                if not result.ok then
                                    tip(result.error)
                                end
                            end)
                        end
                    end
                end
            end
        else
            Wait(500)
        end
        Wait(0)
    end
end)

CreateThread(function()
    for _, stable in ipairs(Config.Stables) do
        if Config.ShowBlips then
            local p = stable.EnterStable
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, p[1], p[2], p[3])
            Citizen.InvokeNative(0x74F74D3207ED525C, blip, stable.BlipIcon, 1)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, stable.Name)
            blips[#blips + 1] = blip
        end
    end
    if Config.SpawnNPCs then
        local model = loadModel('U_M_M_BwmStablehand_01', function()
            return true
        end)
        if model then
            for _, stable in ipairs(Config.Stables) do
                local p = stable.StableNPC
                local ped = CreatePed(model, p[1], p[2], p[3], p[4], false, true, true, true)
                if ped and ped ~= 0 then
                    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
                    SetEntityInvincible(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    FreezeEntityPosition(ped, true)
                    vendors[#vendors + 1] = ped
                end
            end
            SetModelAsNoLongerNeeded(model)
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then
        return
    end
    StablePreload.clear()
    close(true)
    clearRide('horse')
    clearRide('cart')
    if leadPrompt then
        UiPromptDelete(leadPrompt)
    end
    if dismissPrompt then
        UiPromptDelete(dismissPrompt)
    end
    if prompt then
        UiPromptDelete(prompt)
    end
    for _, blip in ipairs(blips) do
        RemoveBlip(blip)
    end
    for _, ped in ipairs(vendors) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)

exports('GetActiveHorse', function()
    return rides.horse and rides.horse.entity
end)

exports('GetActiveWagon', function()
    return rides.cart and rides.cart.entity
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.IsInSession then
            StablePreload.update(GetEntityCoords(PlayerPedId()), opened or opening)
        end
        Wait(Config.Preload.TickMs or 200)
    end
end)
