StableInteractions = {}
local S = StableInteractions
local current

function S.wagonTarget(wagon, target, animals)
    if not wagon or not target or target == 0 then
        return false
    end
    if target == wagon.entity then
        return true
    end
    for _, animal in ipairs(animals or {}) do
        if target == animal then
            return true
        end
    end
    return false
end

local function ledHorse(ped)
    local leading = Citizen.InvokeNative(0xEFC4303DDC6E60D3, ped)
    if leading ~= true and leading ~= 1 then
        return 0
    end
    return Citizen.InvokeNative(0xED1F514AF4732258, ped, Citizen.ResultAsInteger()) or 0
end

local function valid(session)
    return session.ped == PlayerPedId()
        and DoesEntityExist(session.ped)
        and DoesEntityExist(session.entity)
        and DoesEntityExist(session.animal)
        and not IsEntityDead(session.ped)
        and not IsEntityDead(session.animal)
        and not IsPedOnMount(session.ped)
        and not IsPedInAnyVehicle(session.ped, false)
        and (GetRiderOfMount(session.animal) or 0) == 0
end

function S.stop(entity)
    local session = current
    if not session or (entity and session.entity ~= entity) then
        return
    end
    -- Invalidate first, so delayed control/task callbacks cannot restart this lead.
    current = nil
    if DoesEntityExist(session.ped) then
        local animal = ledHorse(session.ped)
        if animal == session.animal or (animal == 0 and session.phase == 'starting') then
            TaskStopLeadingHorse(session.ped)
        end
    end
end

function S.isLeading(entity)
    local session = current
    if not session then
        return false
    end
    if not valid(session) then
        S.stop()
        return false
    end
    if session.phase == 'leading' and ledHorse(session.ped) ~= session.animal then
        current = nil
        return false
    end
    return session.entity == entity
end

function S.lead(entity, animal, done)
    local ped = PlayerPedId()
    local session = { ped = ped, entity = entity, animal = animal, phase = 'control' }
    if not valid(session) then
        done(false, 'Stand beside your horse to lead it.')
        return
    end
    local p, q = GetEntityCoords(ped), GetEntityCoords(animal)
    if (p.x - q.x) ^ 2 + (p.y - q.y) ^ 2 + (p.z - q.z) ^ 2 > 25 then
        done(false, 'Move beside your unoccupied horse to lead it.')
        return
    end
    if current and S.isLeading(entity) and current.animal == animal then
        return
    end
    S.stop()
    current = session
    local attempts = 0
    local function fail(message)
        S.stop()
        done(false, message)
    end
    local function monitor()
        if current ~= session then
            return
        end
        if not valid(session) then
            fail('This horse or draft team cannot be led right now.')
            return
        end
        local actual = ledHorse(ped)
        if session.phase == 'leading' then
            if actual ~= animal then
                current = nil
                return
            end
        elseif actual == animal then
            session.phase = 'leading'
            done(true)
        else
            attempts = attempts + 1
            if attempts >= 20 then
                fail('This horse or draft team cannot be led right now.')
                return
            end
        end
        SetTimeout(200, monitor)
    end
    local controlAttempts = 0
    local function begin()
        if current ~= session then
            return
        end
        if not valid(session) then
            fail('Stand beside your horse to lead it.')
            return
        end
        if not NetworkHasControlOfEntity(animal) then
            controlAttempts = controlAttempts + 1
            if controlAttempts >= 10 then
                fail('Move beside your unoccupied horse to lead it.')
                return
            end
            NetworkRequestControlOfEntity(animal)
            SetTimeout(100, begin)
            return
        end
        -- Recheck distance after waiting for network control.
        local a, b = GetEntityCoords(ped), GetEntityCoords(animal)
        if (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2 > 25 then
            fail('Move beside your unoccupied horse to lead it.')
            return
        end
        session.phase = 'starting'
        TaskLeadHorse(ped, animal)
        SetTimeout(200, monitor)
    end
    begin()
end
