-- 330 Stables — server owner configuration
-- Model/component catalogues: shared/data.lua. Stable positions: locations.lua.
-- Only supported options are listed here. Prices and permissions are checked by the server.

Config = {
    Locale = 'en', -- en / cs; translations are in locales/<language>.json.

    -- Controls and capacity
    Command = 'stables',
    OpenKey = Keys.G,
    CallHorseKey = Keys.H,
    CallCartKey = Keys.J,
    WhistleOnCall = true,
    EnableLeading = true,
    EnableDraftLeading = false, -- Experimental: some harnessed teams refuse the native task.
    InteractionDistance = 18.0, -- includes the front horses of a long draft team.
    HorseCallDistance = 35.0, -- minimum 35m; blocked terrain never falls back to your feet.
    MaxHorses = 3,
    MaxCarts = 1,
    StableSlots = 4,


    -- Purchases and job restrictions
    DisableBuyOption = false,
    JobRequired = false,
    JobForHorseDealer = 'Horsedealer',
    JobForCartDealer = 'Carriagesdealer',
    JobForAllDealer = 'HorseAndCarriagesdealer',
    EquipmentPriceMultiplier = 10,
    WagonSellPercent = 60,
    TransferDistance = 10.0,
    SpawnCooldown = 5000,
    FleeDespawnMs = 10000,
    LongTermHealth = 100, -- Existing VORP injury records at this threshold cannot be called.


    -- VORP Core wallet: cash = currency 0, gold = currency 1.
    -- Inventory's gold item represents this wallet; it is not charged separately.
    Payments = {
        GoldEnabled = true,
        CashPerGold = 25, -- Demo economy rate; choose the rate appropriate for your server.
        GoldPrices = {
            -- A_C_Horse_AmericanStandardbred_Black = 4,
            -- ['275341736'] = 1.25, -- equipment component hash as a string
        },
    },


    -- Interface and world presentation
    SpawnNPCs = true,
    ShowBlips = true,
    MenuReading = { Enabled = true, Scenario = 'WORLD_HUMAN_SIT_GROUND_READING_BOOK' },
    PreviewCamera = { HorsesUseWagonSpot = true, HorseFov = 28.0, WagonFov = 60.0 },
    PreviewTimeout = 6000,
    Thumbnails = {
        -- A_C_Horse_AmericanStandardbred_Black = 'images/standardbred-black.webp',
        -- ['275341736'] = 'images/saddle.webp',
    },


    -- Streaming: menu waits for available models and interface assets.
    EntryTimeoutMs = 25000,
    Preload = {
        Enabled = true,
        AllModels = true,
        Distance = 12.0,
        ReleaseDistance = 24.0,
        BatchSize = 2,
        MaxConcurrent = 3,
        TickMs = 200,
        TimeoutMs = 20000,
    },


    -- Private storage capacity. Each owned ride has its own storage ID.
    DefaultMaxWeight = 125,
    StackInvIgnore = { horse = true, cart = true },
    CustomMaxWeight = {
        huntercart01 = 50,
        cart01 = 50,
        cart02 = 23,
        cart03 = 40,
        cart05 = 28,
        cart06 = 55,
        chuckwagon000x = 105,
        chuckwagon002x = 110,
        wagon02x = 100,
        wagon03x = 65,
        coach2 = 120,
        stagecoach001x = 80,
        stagecoach003x = 250,
        supplywagon = 105,
    },
}
