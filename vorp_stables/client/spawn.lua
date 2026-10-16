StableSpawn = {}

-- Include room in front of the vehicle for the native draft team.
local function clearVolume(p, heading, kind, hash)
    local minimum, maximum = GetModelDimensions(hash)
    local width = math.max(1.6, maximum.x - minimum.x) + 0.8
    local length = math.max(2.4, maximum.y - minimum.y)
    local team = kind == 'cart' and 8.0 or 0.0
    local angle = math.rad(heading)
    local cx, cy = p.x - math.sin(angle) * team / 2, p.y + math.cos(angle) * team / 2
    local height = math.max(2.0, maximum.z - minimum.z)
    -- Keep the probe above the ground so the terrain itself is not an obstruction.
    local handle = StartShapeTestBox(
        cx,
        cy,
        p.z + height / 2 + 0.3,
        width,
        length + team + 1.0,
        height,
        0.0,
        0.0,
        heading,
        2,
        511,
        PlayerPedId(),
        7
    )
    for _ = 1, 20 do
        local status, hit = GetShapeTestResult(handle)
        if status == 2 then
            return not hit or hit == 0
        end
        if status == 0 then
            return false
        end
        Wait(0)
    end
    return false
end

function StableSpawn.find(kind, hash, valid)
    local origin = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    local distance = kind == 'horse'
            and math.max(35.0, math.min(80.0, tonumber((Config or {}).HorseCallDistance) or 35.0))
        or 12.0
    local offsets = {
        { 0, -distance },
        { distance * 0.7, -distance },
        { -distance * 0.7, -distance },
        { 0, distance * 1.25 },
        { distance, 0 },
        { -distance, 0 },
    }
    for _, offset in ipairs(offsets) do
        if not valid() then
            return nil
        end
        local p = GetOffsetFromEntityInWorldCoords(PlayerPedId(), offset[1], offset[2], 0.0)
        local candidateHeading = heading
        if kind == 'cart' then
            local found, road, roadHeading = GetClosestVehicleNodeWithHeading(p.x, p.y, p.z, 1, 3.0, 0)
            if found then
                p, candidateHeading = road, roadHeading
            end
        end
        if (p.x - origin.x) ^ 2 + (p.y - origin.y) ^ 2 <= math.max(45, distance * 1.5) ^ 2 then
            RequestCollisionAtCoord(p.x, p.y, p.z)
            for _ = 1, 12 do
                if HasCollisionLoadedAroundPosition(p.x, p.y, p.z) then
                    break
                end
                Wait(0)
            end
            local found, z = GetGroundZFor_3dCoord(p.x, p.y, p.z + 6.0, false)
            if found and math.abs(z - origin.z) < 5.0 and HasCollisionLoadedAroundPosition(p.x, p.y, z) then
                local level = true
                for _, corner in ipairs({ { -2, -3 }, { 2, -3 }, { -2, 7 }, { 2, 7 } }) do
                    local a = math.rad(candidateHeading)
                    local x = p.x + corner[1] * math.cos(a) - corner[2] * math.sin(a)
                    local y = p.y + corner[1] * math.sin(a) + corner[2] * math.cos(a)
                    local ok, ground = GetGroundZFor_3dCoord(x, y, z + 4.0, false)
                    if not ok or math.abs(ground - z) > 0.7 then
                        level = false
                        break
                    end
                end
                local candidate = { x = p.x, y = p.y, z = z + 0.15 }
                if level and clearVolume(candidate, candidateHeading, kind, hash) and valid() then
                    return candidate, candidateHeading
                end
            end
        end
    end
end
