-- Queue the local stable catalogue without creating hidden preview entities.
StablePreload = {}
local warmedIndex, queue, cursor, jobs, seen, pinned = nil, {}, 1, {}, {}, {}
local loadedCount, failedCount = 0, 0
local failedModels = {}

function StablePreload.clear()
    for hash in pairs(pinned) do
        SetModelAsNoLongerNeeded(hash)
    end
    warmedIndex, queue, cursor, jobs, seen, pinned = nil, {}, 1, {}, {}, {}
    loadedCount, failedCount = 0, 0
    failedModels = {}
end

function StablePreload.release(hash)
    if not pinned[hash] then
        SetModelAsNoLongerNeeded(hash)
    end
end

local function enqueue(model)
    if type(model) ~= 'string' or seen[model:lower()] then
        return
    end
    seen[model:lower()] = true
    queue[#queue + 1] = model
end

function StablePreload.include(rows)
    if not warmedIndex or not Config.Preload.AllModels then
        return
    end
    for _, row in ipairs(rows or {}) do
        enqueue(row.modelname)
    end
end

function StablePreload.status()
    return {
        total = #queue,
        loaded = loadedCount,
        failed = failedCount,
        pending = #queue - loadedCount - failedCount,
    }
end

function StablePreload.isFailed(model)
    return type(model) == 'string' and failedModels[model:lower()] ~= nil
end

local function failed(model, reason)
    failedModels[model:lower()] = reason
    failedCount = failedCount + 1
    print(
        ('[330 Stables] Skipped model %s: %s. Check the catalogue or streaming budget.'):format(model, reason)
    )
end

local function pump(allAtOnce)
    local options = Config.Preload
    local now = GetGameTimer()
    local active = 0
    for hash, job in pairs(jobs) do
        if HasModelLoaded(hash) then
            jobs[hash] = nil
            loadedCount = loadedCount + 1
        elseif now - job.started > (options.TimeoutMs or 6000) then
            jobs[hash] = nil
            pinned[hash] = nil
            SetModelAsNoLongerNeeded(hash)
            failed(job.model, 'loading timed out')
        else
            active = active + 1
        end
    end
    local batch = allAtOnce and (#queue - cursor + 1)
        or math.min(options.BatchSize or 2, math.max(0, (options.MaxConcurrent or 3) - active))
    for _ = 1, batch do
        local model = queue[cursor]
        if not model then
            break
        end
        cursor = cursor + 1
        local hash = GetHashKey(model)
        if IsModelValid(hash) then
            pinned[hash] = true
            jobs[hash] = { started = now, model = model }
            RequestModel(hash, false)
        else
            failed(model, 'model is not available in this game build')
        end
    end
end

function StablePreload.requestAll()
    if warmedIndex then
        pump(true)
    end
end

function StablePreload.poll()
    if warmedIndex then
        pump(false)
    end
end

function StablePreload.prepare(index)
    if not Config.Preload or not Config.Preload.Enabled or (warmedIndex == index and failedCount == 0) then
        return
    end
    StablePreload.clear()
    warmedIndex = index
    local all = Config.Preload.AllModels
    for _, kind in ipairs({ 'horse', 'cart' }) do
        for _, group in ipairs(StableCatalog.rides(index, kind)) do
            for _, coat in ipairs(group.coats) do
                enqueue(coat.model)
                if not all then
                    break
                end
            end
            if not all then
                break
            end
        end
        if not all and #queue > 0 then
            break
        end
    end
    local paths = {}
    for _, image in pairs(Config.Thumbnails or {}) do
        if type(image) == 'string' then
            paths[#paths + 1] = image
        end
    end
    SendNUIMessage({ action = 'preload', images = paths })
end

function StablePreload.update(position, menuOpen)
    local options = Config.Preload
    if not options or not options.Enabled then
        StablePreload.clear()
        return
    end
    if not menuOpen then
        if warmedIndex then
            local p = Config.Stables[warmedIndex].EnterStable
            if
                (position.x - p[1]) ^ 2 + (position.y - p[2]) ^ 2 + (position.z - p[3]) ^ 2
                > (options.ReleaseDistance or 24) ^ 2
            then
                StablePreload.clear()
            end
        end
        if not warmedIndex then
            local nearest, best = nil, (options.Distance or 12) ^ 2
            for index, stable in ipairs(Config.Stables) do
                local p = stable.EnterStable
                local distance = (position.x - p[1]) ^ 2 + (position.y - p[2]) ^ 2 + (position.z - p[3]) ^ 2
                if distance <= best then
                    nearest = index
                    best = distance
                end
            end
            if nearest then
                StablePreload.prepare(nearest)
            end
        end
    end
    if warmedIndex then
        pump()
    end
end
