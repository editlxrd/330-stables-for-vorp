StableReading = {}
local active

local function attachments(ped)
    local result = {}
    for _, entity in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(entity) and IsEntityAttachedToEntity(entity, ped) then
            result[entity] = true
        end
    end
    return result
end

function StableReading.stop()
    local session = active
    active = nil
    if not session then
        return
    end
    local props = {}
    if DoesEntityExist(session.ped) then
        for entity in pairs(attachments(session.ped)) do
            if not session.existing[entity] then
                props[entity] = true
            end
        end
        ClearPedTasksImmediately(session.ped, true, true)
    end
    for entity in pairs(props) do
        if DoesEntityExist(entity) then
            DetachEntity(entity, true, true)
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end
end

function StableReading.start(ped, settings)
    StableReading.stop()
    if not settings.Enabled then
        return
    end
    local existing = attachments(ped)
    -- Also clean a book left by a previous version of this reading scenario.
    local books = { [1210783447] = true } -- Scenario book observed on the supported RedM build.
    for _, model in ipairs({
        'p_book01x',
        'p_book02x',
        'p_book04x',
        'p_cs_bookhardcv01x',
        'p_cs_bookhardcv02x',
        'p_cs_bookhardcv03x',
        'p_cs_bookhardcv04x',
        'p_cs_bookhardcv05x',
        'p_cs_book_oldfieldguide',
        'p_cs_book_forage',
        'p_cs_book_ladyofmanor',
    }) do
        books[GetHashKey(model)] = true
    end
    for entity in pairs(existing) do
        if books[GetEntityModel(entity)] then
            existing[entity] = nil
        end
    end
    active = { ped = ped, existing = existing }
    Citizen.InvokeNative(
        0x524B54361229154F,
        ped,
        GetHashKey(settings.Scenario),
        -1,
        true,
        0,
        GetEntityHeading(ped),
        false
    )
end
