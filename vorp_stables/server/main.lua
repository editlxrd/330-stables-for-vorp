local Core = exports.vorp_core:GetCore()
local epochs, rate, spawnRate = {}, {}, {}
local ready = false
local refundLocks = {}
local receiveRefunds
local adapter = {}

local function decode(value)
    if type(value) == 'table' then
        return value
    end
    if type(value) ~= 'string' then
        return {}
    end
    local ok, out = pcall(json.decode, value)
    return ok and type(out) == 'table' and out or {}
end

local function rowData(row)
    if row then
        row.gear = decode(row.gear)
        row.status = decode(row.status)
    end
    return row
end

function adapter.character(src)
    local user = Core.getUser(src)
    if not user then
        return
    end
    local c = user.getUsedCharacter
    if not c or not c.charIdentifier then
        return
    end
    return {
        id = tonumber(c.charIdentifier),
        identifier = c.identifier,
        job = c.job,
        money = c.money,
        gold = c.gold,
        epoch = epochs[src] or 0,
        source = src,
        character = c,
    }
end

function adapter.valid(src, c)
    local live = adapter.character(src)
    return live and live.id == c.id and live.identifier == c.identifier and live.epoch == c.epoch
end

local function distance(src, coords, radius)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return false
    end
    local p = GetEntityCoords(ped)
    return (p.x - coords[1]) ^ 2 + (p.y - coords[2]) ^ 2 + (p.z - coords[3]) ^ 2 <= radius ^ 2
end

function adapter.nearStable(src, index)
    local s = Config.Stables[index]
    return s and distance(src, s.EnterStable, (s.EnterStable[4] or 2) + 1.0)
end

function adapter.nearPlayers(src, target)
    if GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then
        return false
    end
    local ped = GetPlayerPed(target)
    if not ped or ped == 0 then
        return false
    end
    local q = GetEntityCoords(ped)
    return distance(src, { q.x, q.y, q.z }, Config.TransferDistance)
end

function adapter.players()
    return GetPlayers()
end

function adapter.rows(id)
    local rows = MySQL.query.await(
        [[SELECT * FROM stables WHERE charidentifier=? OR JSON_UNQUOTE(JSON_EXTRACT(IF(JSON_VALID(status),status,'{}'),'$.transferTarget'))=? ORDER BY id]],
        { id, tostring(id) }
    ) or {}
    for _, row in ipairs(rows) do
        rowData(row)
    end
    return rows
end

function adapter.row(id)
    return rowData(MySQL.single.await('SELECT * FROM stables WHERE id=?', { id }))
end

function adapter.complements(id)
    local row =
        MySQL.single.await('SELECT complements FROM horse_complements WHERE charidentifier=? LIMIT 1', { id })
    return row and decode(row.complements) or {}
end

function adapter.insert(c, name, model, kind, active, paid, currency)
    return MySQL.insert.await(
        'INSERT INTO stables (charidentifier,identifier,name,modelname,type,gear,isDefault,status) VALUES (?,?,?,?,?,?,?,?)',
        {
            c.id,
            c.identifier,
            name,
            model,
            kind,
            '{}',
            active and 1 or 0,
            json.encode({ purchasePrice = paid, purchaseCurrency = currency or 'cash' }),
        }
    )
end

function adapter.update(id, owner, fields)
    local field, value = next(fields)
    if field ~= 'name' and field ~= 'gear' and field ~= 'status' then
        return false
    end
    -- false encodes JSON false, so the old transferTarget is removed without nil SQL parameters.
    if field == 'gear' or field == 'status' then
        value = json.encode(value)
    end
    return MySQL.update.await(
        ('UPDATE stables SET `%s`=? WHERE id=? AND charidentifier=?'):format(field),
        { value, id, owner }
    ) > 0
end

function adapter.storageEmpty(row)
    return StableStorage.empty(row)
end

function adapter.delete(id, owner)
    return MySQL.update.await('DELETE FROM stables WHERE id=? AND charidentifier=?', { id, owner }) > 0
end

local function refundTable(currency)
    return currency == 'gold' and 'stable_gold_refunds' or 'stable_refunds'
end

function adapter.sell(c, row, amount, currency)
    -- Ownership removal and a durable payout claim commit together.
    local saved = MySQL.transaction.await({
        {
            query = 'INSERT INTO '
                .. refundTable(currency)
                .. ' (charidentifier,amount) SELECT charidentifier,? FROM stables WHERE id=? AND charidentifier=? AND type=?',
            values = { amount, row.id, c.id, 'cart' },
        },
        {
            query = 'DELETE FROM stables WHERE id=? AND charidentifier=? AND type=?',
            values = { row.id, c.id, 'cart' },
        },
    })
    if not saved then
        return false
    end
    receiveRefunds(c.source, c)
    return true
end

function adapter.setDefault(id, owner, kind)
    return MySQL.transaction.await({
        {
            query = 'UPDATE stables SET isDefault=0 WHERE charidentifier=? AND type=?',
            values = { owner, kind },
        },
        {
            query = 'UPDATE stables SET isDefault=1 WHERE id=? AND charidentifier=? AND type=?',
            values = { id, owner, kind },
        },
    })
end

function adapter.equipment(id, owner, gear, owned)
    local row = MySQL.single.await(
        'SELECT charidentifier FROM horse_complements WHERE charidentifier=? LIMIT 1',
        { owner }
    )
    return MySQL.transaction.await({
        {
            query = 'UPDATE stables SET gear=? WHERE id=? AND charidentifier=?',
            values = { json.encode(gear), id, owner },
        },
        row
                and {
                    query = 'UPDATE horse_complements SET complements=? WHERE charidentifier=?',
                    values = { json.encode(owned), owner },
                }
            or {
                query = 'INSERT INTO horse_complements (identifier,charidentifier,complements) VALUES (?,?,?)',
                values = { tostring(owner), owner, json.encode(owned) },
            },
    })
end

function adapter.transfer(id, owner, target, paid, currency)
    return MySQL.update.await(
        'UPDATE stables SET charidentifier=?,identifier=?,status=?,isDefault=0 WHERE id=? AND charidentifier=?',
        {
            target.id,
            target.identifier,
            json.encode(
                StableCatalog.amount(paid) and { purchasePrice = paid, purchaseCurrency = currency or 'cash' }
                    or {}
            ),
            id,
            owner,
        }
    ) > 0
end

function adapter.debit(c, amount, currency)
    local field = currency == 'gold' and 'gold' or 'money'
    local current = adapter.character(c.source)
    if not current or not adapter.valid(c.source, c) or (current[field] or 0) < amount then
        return false
    end
    if amount > 0 then
        current.character.removeCurrency(currency == 'gold' and 1 or 0, amount)
    end
    c[field] = (current[field] or 0) - amount
    return true
end

function adapter.credit(c, amount, currency)
    local field = currency == 'gold' and 'gold' or 'money'
    if amount == 0 then
        return
    end
    if adapter.valid(c.source, c) then
        c.character.addCurrency(currency == 'gold' and 1 or 0, amount)
    else
        -- Disconnected VORP characters are saved by Core; defer compensation to the next session.
        MySQL.insert.await(
            'INSERT INTO ' .. refundTable(currency) .. ' (charidentifier,amount) VALUES (?,?)',
            { c.id, amount }
        )
    end
    c[field] = (c[field] or 0) + amount
end

function adapter.log(message)
    print('[330 Stables] ' .. message)
end
local service = StableService.new(adapter)

receiveRefunds = function(src, c)
    if refundLocks[c.id] then
        return false
    end
    refundLocks[c.id] = true
    local ok, err = pcall(function()
        for _, currency in ipairs({ 'cash', 'gold' }) do
            local refunds = MySQL.query.await(
                'SELECT id,amount FROM ' .. refundTable(currency) .. ' WHERE charidentifier=? ORDER BY id',
                { c.id }
            ) or {}
            for _, refund in ipairs(refunds) do
                if not adapter.valid(src, c) then
                    break
                end
                local amount = tonumber(refund.amount)
                if StableCatalog.amount(amount) then
                    local removed = MySQL.update.await(
                        'DELETE FROM ' .. refundTable(currency) .. ' WHERE id=? AND charidentifier=?',
                        { refund.id, c.id }
                    )
                    if removed > 0 then
                        local credited, problem = pcall(adapter.credit, c, amount, currency)
                        if not credited then
                            MySQL.insert.await(
                                'INSERT INTO '
                                    .. refundTable(currency)
                                    .. ' (charidentifier,amount) VALUES (?,?)',
                                { c.id, amount }
                            )
                            error(problem)
                        end
                    end
                else
                    adapter.log('Skipped invalid deferred refund ' .. tostring(refund.id))
                end
            end
        end
    end)
    refundLocks[c.id] = nil
    if not ok then
        adapter.log('Deferred refund processing failed: ' .. tostring(err))
    end
    return ok
end

local function openStorage(src, row, netId)
    if not StableCatalog.integer(netId) then
        return false
    end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if
        not entity
        or entity == 0
        or not DoesEntityExist(entity)
        or NetworkGetEntityOwner(entity) ~= src
        or GetEntityModel(entity) ~= GetHashKey(row.modelname)
    then
        return false
    end
    local q = GetEntityCoords(entity)
    if not distance(src, { q.x, q.y, q.z }, 4.0) then
        return false
    end
    if GetResourceState('lab_inventory') == 'started' then
        local found = exports.lab_inventory:ResolveOwnedStorage(
            src,
            row.type == 'horse' and 'horse' or 'wagon',
            { netId = netId, stableId = tostring(row.id) }
        )
        return found and exports.lab_inventory:OpenStash(src, found.id).ok or false
    end
    if GetResourceState('vorp_inventory') ~= 'started' then
        return false
    end
    local id = 'stable_' .. row.id
    if not exports.vorp_inventory:isCustomInventoryRegistered(id) then
        local options = {
            id = id,
            name = row.name,
            limit = Config.CustomMaxWeight[row.modelname] or Config.DefaultMaxWeight,
            acceptWeapons = true,
            shared = false,
            ignoreItemStackLimit = Config.StackInvIgnore[row.type],
        }
        local ok, registered = pcall(function()
            return exports.vorp_inventory:registerInventory(options)
        end)
        if not ok then
            local api = exports.vorp_inventory:vorp_inventoryApi()
            registered = api.registerInventory(
                id,
                options.name,
                options.limit,
                true,
                false,
                options.ignoreItemStackLimit
            )
        end
        if registered == false then
            return false
        end
    end
    exports.vorp_inventory:openInventory(src, id)
    return true
end

RegisterNetEvent('330_stables:request', function(id, request)
    local src = source
    if not StableCatalog.integer(id) or type(request) ~= 'table' then
        return
    end
    local now = GetGameTimer()
    if rate[src] and now - rate[src] < 120 then
        TriggerClientEvent('330_stables:response', src, id, { ok = false, error = 'Please slow down.' })
        return
    end
    rate[src] = now
    if not ready then
        TriggerClientEvent(
            '330_stables:response',
            src,
            id,
            { ok = false, error = 'The stable is starting. Try again in a moment.' }
        )
        return
    end
    local before = adapter.character(src)
    if not before then
        return
    end
    if (request.action == 'open' or request.action == 'refresh') and not receiveRefunds(src, before) then
        TriggerClientEvent(
            '330_stables:response',
            src,
            id,
            { ok = false, error = 'Your wallet is updating. Please try again.' }
        )
        return
    end
    if request.action == 'spawn' and spawnRate[src] and now - spawnRate[src] < Config.SpawnCooldown then
        TriggerClientEvent(
            '330_stables:response',
            src,
            id,
            { ok = false, error = 'Wait a moment before calling another ride.' }
        )
        return
    end
    local result = service.handle(src, request)
    if not adapter.valid(src, before) then
        return
    end
    if result.ok and result.spawn then
        spawnRate[src] = now
    end
    if result.ok and result.inventory then
        local ok, opened = pcall(openStorage, src, result.inventory, request.netId)
        result = {
            ok = ok and opened == true,
            error = not (ok and opened) and 'Move closer to your ride and try again.' or nil,
        }
    end
    if result.ok and (result.dismiss or result.lead) then
        local row = result.dismiss or result.lead
        local netId = request.netId
        local entity = StableCatalog.integer(netId) and NetworkGetEntityFromNetworkId(netId) or 0
        local allowed = entity
            and entity ~= 0
            and DoesEntityExist(entity)
            and NetworkGetEntityOwner(entity) == src
            and GetEntityModel(entity) == GetHashKey(row.modelname)
        if allowed then
            local q = GetEntityCoords(entity)
            allowed = distance(src, { q.x, q.y, q.z }, Config.InteractionDistance or 18.0)
            for _, player in ipairs(GetPlayers()) do
                local ped = GetPlayerPed(tonumber(player))
                if ped and ped ~= 0 and GetVehiclePedIsIn(ped, false) == entity then
                    allowed = false
                    break
                end
            end
        end
        result = {
            ok = allowed == true,
            error = not allowed and 'Move beside your empty wagon to dismiss it.' or nil,
        }
    end
    TriggerClientEvent('330_stables:response', src, id, result)
    if
        result.ok
        and request.action ~= 'spawn'
        and request.action ~= 'open'
        and request.action ~= 'refresh'
        and request.action ~= 'inventory'
        and request.action ~= 'dismiss'
        and request.action ~= 'lead'
    then
        TriggerClientEvent('330_stables:changed', -1)
    end
end)

AddEventHandler('playerDropped', function()
    epochs[source] = (epochs[source] or 0) + 1
    rate[source] = nil
    spawnRate[source] = nil
end)
MySQL.ready(function()
    local schema = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql')
    for query in schema:gmatch('CREATE TABLE IF NOT EXISTS.-;') do
        MySQL.query.await(query)
    end
    MySQL.query.await(
        'CREATE TABLE IF NOT EXISTS stable_refunds (id INT AUTO_INCREMENT PRIMARY KEY,charidentifier INT NOT NULL,amount DECIMAL(12,2) NOT NULL) ENGINE=InnoDB'
    )
    MySQL.query.await(
        'CREATE TABLE IF NOT EXISTS stable_gold_refunds (id INT AUTO_INCREMENT PRIMARY KEY,charidentifier INT NOT NULL,amount DECIMAL(12,2) NOT NULL) ENGINE=InnoDB'
    )
    ready = true
    print('[330 Stables] Ready. VORP connected; stable records loaded.')
end)
