-- All economic/ownership decisions live here. The adapter is the only database/native boundary.
StableService = {}

function StableService.new(a)
    local locks = {}
    local C = StableCatalog
    local function fail(message)
        error({ public = message }, 0)
    end
    local function ensure(condition, message)
        if not condition then
            fail(message)
        end
    end
    local function live(src, c)
        ensure(a.valid(src, c), 'Your character session changed. Reopen the stable.')
    end
    local function owned(c, id)
        ensure(C.integer(id), 'Choose a valid ride.')
        local row = a.row(id)
        ensure(row and tonumber(row.charidentifier) == c.id, 'This ride does not belong to you.')
        return row
    end
    local function capacity(rows, kind)
        local count, total = 0, 0
        for _, row in ipairs(rows) do
            if not row.incoming then
                total = total + 1
                if row.type == kind then
                    count = count + 1
                end
            end
        end
        return count < (kind == 'horse' and Config.MaxHorses or Config.MaxCarts)
            and total < Config.StableSlots
    end
    local function snapshot(src, c, index)
        local rides, offers = {}, {}
        for _, row in ipairs(a.rows(c.id)) do
            row.gear = type(row.gear) == 'table' and row.gear or {}
            if tonumber(row.charidentifier) == c.id then
                if row.type == 'cart' then
                    row.sellCurrency = type(row.status) == 'table'
                            and row.status.purchaseCurrency == 'gold'
                            and 'gold'
                        or 'cash'
                    row.sellPrice = C.wagonSalePrice(
                        row.modelname,
                        type(row.status) == 'table' and row.status.purchasePrice
                    )
                end
                rides[#rides + 1] = row
            elseif type(row.status) == 'table' and row.status.transferTarget == c.id then
                row.incoming = true
                offers[#offers + 1] = row
            end
        end
        live(src, c)
        return {
            rides = rides,
            offers = offers,
            ownedGear = a.complements(c.id),
            cash = c.money,
            gold = c.gold or 0,
            location = index and Config.Stables[index].Name,
            stable = index,
            horses = index and C.rides(index, 'horse') or {},
            wagons = index and C.rides(index, 'cart') or {},
            equipment = index and C.equipmentGroups() or {},
            limits = { horses = Config.MaxHorses, wagons = Config.MaxCarts, total = Config.StableSlots },
        }
    end
    local function playerFor(id)
        for _, src in ipairs(a.players()) do
            local c = a.character(tonumber(src))
            if c and c.id == id then
                return tonumber(src), c
            end
        end
    end
    local function hasOffer(row)
        return type(row.status) == 'table' and row.status.transferTarget
    end
    local service = {}
    function service.handle(src, r)
        if type(r) ~= 'table' or type(r.action) ~= 'string' then
            return { ok = false, error = 'Invalid stable request.' }
        end
        local c = a.character(src)
        if not c then
            return { ok = false, error = 'Select a character first.' }
        end
        if locks[c.id] then
            return { ok = false, error = 'Please wait for your previous action.' }
        end
        local keys = { c.id }
        locks[c.id] = true
        local ok, result = xpcall(function()
            local action = r.action
            local remote = action == 'spawn'
                or action == 'inventory'
                or action == 'refresh'
                or action == 'dismiss'
                or action == 'lead'
            if not remote then
                ensure(
                    C.integer(r.stable) and Config.Stables[r.stable] and a.nearStable(src, r.stable),
                    'Visit the stable to do this.'
                )
            end
            if action == 'open' or action == 'refresh' then
                return { ok = true, data = snapshot(src, c, action == 'open' and r.stable or nil) }
            end
            if action == 'buy' then
                ensure(not Config.DisableBuyOption, 'Purchases are disabled.')
                if Config.JobRequired then
                    ensure(
                        c.job == Config.JobForAllDealer
                            or c.job
                                == (r.kind == 'horse' and Config.JobForHorseDealer or Config.JobForCartDealer),
                        'Your job cannot buy this ride.'
                    )
                end
                local name = C.name(r.name)
                ensure(name, 'Use a name with 3–30 characters.')
                local price = C.price(r.stable, r.kind, r.model)
                ensure(price and C.amount(price), 'This model is not sold here.')
                local currency
                price, currency = C.payment(r.currency, price, r.model)
                ensure(price and C.amount(price), 'This payment method is not available.')
                local rows = a.rows(c.id)
                local mine = {}
                local active = false
                for _, row in ipairs(rows) do
                    if tonumber(row.charidentifier) == c.id then
                        mine[#mine + 1] = row
                        if row.type == r.kind and row.isDefault == 1 then
                            active = true
                        end
                    end
                end
                ensure(capacity(mine, r.kind), 'Your stable has no room for this ride.')
                live(src, c)
                ensure(
                    (currency == 'gold' and (c.gold or 0) or c.money) >= price,
                    'You cannot afford this ride in the selected currency.'
                )
                ensure(
                    a.debit(c, price, currency) ~= false,
                    'Your wallet changed. You cannot afford this ride.'
                )
                local saved, id = pcall(a.insert, c, name, r.model, r.kind, not active, price, currency)
                if not saved or not id then
                    a.credit(c, price, currency)
                    fail('Purchase failed. Your payment was returned.')
                end
            elseif action == 'accept' or action == 'reject' then
                ensure(C.integer(r.id), 'Choose a valid offer.')
                local row = a.row(r.id)
                local offer = row and row.status
                ensure(
                    type(offer) == 'table' and offer.transferTarget == c.id,
                    'This offer is no longer available.'
                )
                local sellerSrc, seller = playerFor(tonumber(row.charidentifier))
                ensure(
                    seller and seller.id ~= c.id and a.nearPlayers(src, sellerSrc),
                    'The owner must be online and nearby.'
                )
                ensure(not locks[seller.id], 'The owner is busy. Try again.')
                locks[seller.id] = true
                keys[#keys + 1] = seller.id
                if action == 'reject' then
                    live(src, c)
                    ensure(
                        a.update(row.id, seller.id, {
                            status = C.receipt(row.status),
                        }),
                        'Could not decline this offer.'
                    )
                else
                    ensure(C.amount(offer.price), 'Invalid transfer price.')
                    local mine = {}
                    for _, v in ipairs(a.rows(c.id)) do
                        if tonumber(v.charidentifier) == c.id then
                            mine[#mine + 1] = v
                        end
                    end
                    ensure(capacity(mine, row.type), 'Your stable has no room for this ride.')
                    live(src, c)
                    live(sellerSrc, seller)
                    ensure(c.money >= offer.price, 'You cannot afford this offer.')
                    ensure(
                        a.debit(c, offer.price) ~= false,
                        'Your wallet changed. You cannot afford this offer.'
                    )
                    local saved, changed =
                        pcall(a.transfer, row.id, seller.id, c, offer.purchasePrice, offer.purchaseCurrency)
                    if not saved or not changed then
                        a.credit(c, offer.price)
                        fail('Transfer failed. Your payment was returned.')
                    end
                    a.credit(seller, offer.price)
                end
            elseif action == 'spawn' then
                ensure(r.kind == 'horse' or r.kind == 'cart', 'Choose a horse or wagon.')
                local row
                for _, v in ipairs(a.rows(c.id)) do
                    if
                        tonumber(v.charidentifier) == c.id
                        and v.type == r.kind
                        and tonumber(v.isDefault) == 1
                    then
                        row = v
                        break
                    end
                end
                ensure(row, 'Select an active ride in My Stable first.')
                ensure(not hasOffer(row), 'Cancel the transfer offer before calling this ride.')
                ensure(
                    (tonumber(row.injured) or 0) < Config.LongTermHealth,
                    'This horse is unavailable because of its injuries.'
                )
                live(src, c)
                return { ok = true, spawn = row }
            else
                local row = owned(c, r.id)
                live(src, c)
                if action ~= 'cancelOffer' then
                    ensure(not hasOffer(row), 'Cancel the pending transfer first.')
                end
                if action == 'rename' then
                    local name = C.name(r.name)
                    ensure(name, 'Use a name with 3–30 characters.')
                    ensure(a.update(row.id, c.id, { name = name }), 'Could not rename this ride.')
                elseif action == 'active' then
                    ensure(a.setDefault(row.id, c.id, row.type), 'Could not select this ride.')
                elseif action == 'sell' then
                    ensure(row.type == 'cart', 'Only wagons can be sold here.')
                    ensure(
                        not a.storageEmpty or a.storageEmpty(row),
                        'Empty the wagon storage first. Its inventory must be available for verification.'
                    )
                    live(src, c)
                    ensure(r.confirm == true, 'Confirm the wagon sale.')
                    local price = C.wagonSalePrice(
                        row.modelname,
                        type(row.status) == 'table' and row.status.purchasePrice
                    )
                    ensure(C.amount(price), 'This wagon has no configured resale value.')
                    ensure(
                        a.sell(
                            c,
                            row,
                            price,
                            type(row.status) == 'table' and row.status.purchaseCurrency == 'gold' and 'gold'
                                or 'cash'
                        ),
                        'Sale failed. Your wagon remains in the stable.'
                    )
                elseif action == 'release' then
                    ensure(row.type == 'horse', 'Use Sell wagon instead of releasing a wagon.')
                    ensure(
                        not a.storageEmpty or a.storageEmpty(row),
                        'Empty the horse storage first. Its inventory must be available for verification.'
                    )
                    live(src, c)
                    ensure(r.confirm == true, 'Confirm that you want to permanently release this ride.')
                    ensure(a.delete(row.id, c.id), 'Could not release this ride.')
                elseif action == 'equip' then
                    ensure(row.type == 'horse', 'Equipment can only be fitted to a horse.')
                    local item = C.equipment(r.family, r.hash)
                    ensure(item, 'Choose valid equipment.')
                    local equipment = a.complements(c.id)
                    local exists = tonumber((row.gear or {})[item.family]) == item.hash
                    for _, hash in ipairs(equipment) do
                        if tonumber(hash) == item.hash then
                            exists = true
                            break
                        end
                    end
                    local price, currency = C.payment(r.currency, item.price, item.hash)
                    ensure(price and C.amount(price), 'This payment method is not available.')
                    price = exists and 0 or price
                    live(src, c)
                    ensure(
                        (currency == 'gold' and (c.gold or 0) or c.money) >= price,
                        'You cannot afford this equipment in the selected currency.'
                    )
                    local gear = type(row.gear) == 'table' and row.gear or {}
                    gear[item.family] = item.hash
                    if not exists then
                        equipment[#equipment + 1] = item.hash
                    end
                    ensure(
                        a.debit(c, price, currency) ~= false,
                        'Your wallet changed. You cannot afford this equipment.'
                    )
                    local saved, changed = pcall(a.equipment, row.id, c.id, gear, equipment)
                    if not saved or not changed then
                        a.credit(c, price, currency)
                        fail('Equipment could not be saved. Your payment was returned.')
                    end
                elseif action == 'removeGear' then
                    ensure(a.update(row.id, c.id, { gear = {} }), 'Could not remove equipment.')
                elseif action == 'offer' then
                    ensure(
                        C.integer(r.target) and r.target ~= src and C.amount(r.price),
                        'Choose a nearby player and a valid price.'
                    )
                    local target = a.character(r.target)
                    ensure(
                        target and target.id ~= c.id and a.nearPlayers(src, r.target),
                        'The recipient must be online and nearby.'
                    )
                    ensure(
                        a.update(row.id, c.id, {
                            status = {
                                transferTarget = target.id,
                                price = r.price,
                                purchaseCurrency = type(row.status) == 'table'
                                        and row.status.purchaseCurrency
                                    or 'cash',
                                purchasePrice = type(row.status) == 'table' and row.status.purchasePrice
                                    or nil,
                            },
                        }),
                        'Could not send this offer.'
                    )
                elseif action == 'cancelOffer' then
                    ensure(
                        a.update(row.id, c.id, {
                            status = C.receipt(row.status),
                        }),
                        'Could not cancel this offer.'
                    )
                elseif action == 'lead' then
                    return { ok = true, lead = row }
                elseif action == 'dismiss' then
                    ensure(row.type == 'cart', 'Choose your own wagon.')
                    return { ok = true, dismiss = row }
                elseif action == 'inventory' then
                    return { ok = true, inventory = row }
                else
                    fail('Unknown stable action.')
                end
            end
            live(src, c)
            return { ok = true, data = snapshot(src, c, r.stable), message = 'Your stable has been updated.' }
        end, function(err)
            return err
        end)
        for _, key in ipairs(keys) do
            locks[key] = nil
        end
        if not ok then
            if type(result) == 'table' and result.public then
                return { ok = false, error = result.public }
            end
            if a.log then
                a.log(tostring(result))
            end
            return { ok = false, error = 'The stable could not complete this action. Please try again.' }
        end
        return result
    end
    return service
end
