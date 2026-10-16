-- Stable entrances, preview positions, cameras and vendor catalogues.

Config.Stables = { -- locations retain the original VORP ordering and IDs.
    -- Empty horses/carts lists sell the full catalogue. A map entry overrides its price.
    -- Example: horses = { A_C_Horse_AmericanStandardbred_Black = 100 }

    {
        Name = 'Stable of Valentine',
        BlipIcon = 1938782895,
        EnterStable = { -365.87, 789.51, 116.17, 2.0 },
        StableNPC = { -365.15, 792.68, 115.18, 178.47 },
        SpawnHorse = { -366.07, 781.81, 115.14, 5.97 },
        CamHorse = { -367.9267, 783.0237, 117.7778, -36.42624, 0.0, -100.9786 },
        CamHorseGear = { -367.9267, 783.0237, 117.7778, -36.42624, 0.0, -100.9786 },
        SpawnCart = { -370.11, 786.99, 115.16, 274.18 },
        CamCart = { -363.5831, 792.1113, 118.0419, -16.35144, 0.0, 143.9759 },
        -- horses available and prices
        horses = {
            A_C_Horse_AmericanStandardbred_Black = 100,
            A_C_Horse_AmericanStandardbred_Buckskin = 100,
            A_C_Horse_AmericanStandardbred_Lightbuckskin = 100,
            A_C_Horse_AmericanStandardbred_PalominoDapple = 100,
            A_C_Horse_AmericanStandardbred_SilverTailBuckskin = 100,

            A_C_Horse_Breton_GrulloDun = 100,
            A_C_Horse_Breton_RedRoan = 100,
            A_C_Horse_Breton_Sorrel = 100,
            A_C_Horse_Breton_SteelGrey = 100,
            A_C_Horse_Breton_SealBrown = 100,

            A_C_Horse_KentuckySaddle_Black = 100,
            A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC = 100,
            A_C_Horse_KentuckySaddle_ChestnutPinto = 100,
            A_C_Horse_KentuckySaddle_Grey = 100,
            A_C_Horse_KentuckySaddle_SilverBay = 100,

            A_C_Horse_Kladruber_Black = 100,
            A_C_Horse_Kladruber_Silver = 100,
            A_C_Horse_Kladruber_Cremello = 100,

            A_C_Horse_Morgan_FlaxenChestnut = 100,
            A_C_Horse_Morgan_LiverChestnut_PC = 100,

            A_C_Horse_NorfolkRoadster_RoseGrey = 100,
            A_C_Horse_NorfolkRoadster_SpeckledGrey = 100,
            A_C_Horse_NorfolkRoadster_SpottedTricolor = 100,

            A_C_Horse_Shire_DarkBay = 100,
            A_C_Horse_Shire_LightGrey = 100,
            A_C_Horse_Shire_RavenBlack = 100,

            A_C_Horse_TennesseeWalker_BlackRabicano = 100,
            A_C_Horse_TennesseeWalker_Chestnut = 100,
            A_C_Horse_TennesseeWalker_MahoganyBay = 100,
            A_C_Horse_TennesseeWalker_RedRoan = 100,

            A_C_Horse_Turkoman_DarkBay = 100,
            A_C_Horse_Turkoman_Gold = 100,
            A_C_Horse_Turkoman_Silver = 100,

            A_C_HorseMule_01 = 100,
        },
        -- carts available and prices
        carts = {
            huntercart01 = 50,
            cart01 = 30,
            cart02 = 23,
            cart05 = 28,
            chuckwagon002x = 110,
            wagon02x = 100,
            wagon03x = 65,
            coach2 = 120,
            stagecoach001x = 80,
            supplywagon = 105,
        },
    },
    {
        Name = 'Stable of Rhodes',
        BlipIcon = 1938782895,
        EnterStable = { 1432.97, -1295.39, 76.82, 2.0 },
        StableNPC = { 1434.64, -1294.89, 76.82, 105.08 },
        SpawnHorse = { 1431.56, -1288.21, 76.82, 87.28 },
        CamHorse = { 1431.58, -1292.27, 79.0, -16.0, 0.0, 6.0 },
        CamHorseGear = { 1431.58, -1292.27, 79.0, -16.0, 0.0, 6.0 },
        SpawnCart = { 1414.53, -1294.22, 77.95, 285.53 },
        CamCart = { 1416.7, -1301.12, 81.0, -16.0, 0.0, 6.0 },
        horses = {
            A_C_Horse_Ardennes_BayRoan = 100,
            A_C_Horse_Ardennes_IronGreyRoan = 100,
            A_C_Horse_Ardennes_StrawberryRoan = 100,

            A_C_Horse_Belgian_BlondChestnut = 100,
            A_C_Horse_Belgian_MealyChestnut = 100,

            A_C_Horse_KentuckySaddle_Black = 100,
            A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC = 100,
            A_C_Horse_KentuckySaddle_ChestnutPinto = 100,
            A_C_Horse_KentuckySaddle_Grey = 100,
            A_C_Horse_KentuckySaddle_SilverBay = 100,

            A_C_Horse_Kladruber_Grey = 100,
            A_C_Horse_Kladruber_DappleRoseGrey = 100,
            A_C_Horse_Kladruber_White = 100,

            A_C_Horse_Morgan_Bay = 100,
            A_C_Horse_Morgan_BayRoan = 100,
            A_C_Horse_Morgan_Palomino = 100,

            A_C_Horse_NorfolkRoadster_Black = 100,
            A_C_Horse_NorfolkRoadster_DappledBuckskin = 100,
            A_C_Horse_NorfolkRoadster_PiebaldRoan = 100,

            A_C_Horse_SuffolkPunch_RedChestnut = 100,
            A_C_Horse_SuffolkPunch_Sorrel = 100,

            A_C_Horse_TennesseeWalker_DappleBay = 100,
            A_C_Horse_TennesseeWalker_FlaxenRoan = 100,
            A_C_Horse_TennesseeWalker_GoldPalomino_PC = 100,

            A_C_HorseMule_01 = 100,
            A_C_Donkey_01 = 100,
        },
        carts = {
            huntercart01 = 50,
            cart03 = 40,
            cart06 = 55,
            chuckwagon000x = 105,
            wagon02x = 100,
            wagon03x = 65,
            stagecoach003x = 250,
            supplywagon = 105,
        },
    },
    {
        Name = 'Stable of Wapiti',
        BlipIcon = 1938782895,
        EnterStable = { 482.06, 2215.17, 247.16, 2.0 },
        StableNPC = { 480.43, 2213.17, 245.90, -44.71 },
        SpawnHorse = { 485.49, 2209.0, 245.70, -27.54 },
        CamHorse = { 483.39, 2211.93, 248.0, -19.14523, 0.0, 225.0 },
        CamHorseGear = { 483.39, 2211.93, 247.58, -19.14523, 0.0, 225.0 },
        SpawnCart = { 489.04, 2212.9, 246.95, -67.0 },
        CamCart = { 483.36, 2219.16, 250.76, -25.0, 0.0, 233.68 },
        horses = {
            A_C_Horse_AmericanPaint_Greyovero = 100,
            A_C_Horse_AmericanPaint_Overo = 100,
            A_C_Horse_AmericanPaint_SplashedWhite = 100,
            A_C_Horse_AmericanPaint_Tobiano = 100,

            A_C_Horse_Appaloosa_BlackSnowflake = 100,
            A_C_Horse_Appaloosa_Blanket = 100,
            A_C_Horse_Appaloosa_BrownLeopard = 100,
            A_C_Horse_Appaloosa_FewSpotted_PC = 100,
            A_C_Horse_Appaloosa_Leopard = 100,
            A_C_Horse_Appaloosa_LeopardBlanket = 100,

            A_C_Horse_Mustang_BlackOvero = 100,
            A_C_Horse_Mustang_GoldenDun = 100,
            A_C_Horse_Mustang_GrulloDun = 100,
            A_C_Horse_Mustang_TigerStripedBay = 100,
            A_C_Horse_Mustang_RedDunOvero = 100,
            A_C_Horse_Mustang_WildBay = 100,
            A_C_Horse_Mustang_Buckskin = 100,
            A_C_Horse_Mustang_ChestNuttOvero = 100,

            A_C_Horse_Nokota_BlueRoan = 100,
            A_C_Horse_Nokota_ReverseDappleRoan = 100,
            A_C_Horse_Nokota_WhiteRoan = 100,
        },
        carts = {
            huntercart01 = 50,
            cart03 = 40,
            chuckwagon002x = 110,
            wagon02x = 100,
        },
    },

    {
        Name = 'Saint Denis Stable',
        BlipIcon = 1938782895,
        EnterStable = { 2510.58, -1456.83, 46.31, 2.0 },
        StableNPC = { 2512.35, -1456.89, 45.2, 91.68 },
        SpawnHorse = { 2508.59, -1449.96, 45.5, 90.09 },
        CamHorse = { 2506.807, -1452.29, 48.61699, -34.77003, 0.0, -35.20742 },
        CamHorseGear = { 2508.876, -1451.953, 48.67999, -35.29771, 0.0, -0.4993192 },
        SpawnCart = { 2503.47, -1441.89, 46.31, 0.24 },
        CamCart = { 2506.428, -1437.7, 50.57832, -39.4497, 0.0, 120.535 },
    },
    {
        Name = 'Strawberry Stable',
        BlipIcon = 1938782895,
        EnterStable = { -1816.81, -561.99, 156.07, 2.0 },
        StableNPC = { -1818.45, -564.83, 155.06, 347.22 },
        SpawnHorse = { -1820.26, -555.84, 155.16, 163.01 },
        CamHorse = { -1819.512, -558.6999, 157.6765, -23.95241, 0.0, 28.46066 },
        CamHorseGear = { -1819.512, -558.6999, 157.6765, -23.95241, 0.0, 28.46066 },
        SpawnCart = { -1821.46, -561.41, 155.06, 256.24 },
        CamCart = { -1816.372, -560.2017, 157.6678, -22.02157, 0.0, 124.3779 },
    },
    {
        Name = 'Blackwater Stable',
        BlipIcon = 1938782895,
        EnterStable = { -876.57, -1365.1, 43.53, 2.0 },
        StableNPC = { -878.35, -1364.81, 42.53, 266.28 },
        SpawnHorse = { -864.25, -1361.8, 42.7, 177.48 },
        CamHorse = { -862.6163, -1362.927, 45.58158, -40.96593, 0.0, 71.8129 },
        CamHorseGear = { -862.6163, -1362.927, 45.58158, -40.96593, 0.0, 71.8129 },
        SpawnCart = { -872.58, -1366.57, 42.53, 270.35 },
        CamCart = { -869.7852, -1361.103, 45.26991, -17.11994, 0.0, 161.4039 },
    },
    {
        Name = 'Tumbleweed Stable',
        BlipIcon = 1938782895,
        EnterStable = { -5514.24, -3041.81, -2.39, 2.0 },
        StableNPC = { -5515.07, -3039.51, -3.39, 179.88 },
        SpawnHorse = { -5519.47, -3039.32, -3.31, 181.62 },
        CamHorse = { -5517.651, -3041.113, -0.50949, -33.14523, 0.0, 55.47822 },
        CamHorseGear = { -5517.651, -3041.113, -0.50949, -33.14523, 0.0, 55.47822 },
        SpawnCart = { -5520.65, -3044.3, -3.39, 270.83 },
        CamCart = { -5514.191, -3040.633, -0.5108569, -18.79705, 0.0, 141.3175 },
    },
}

-- Side view suited to the approved left-hand catalogue.
Config.Stables[1].Name = 'Valentine Stable'
Config.Stables[1].CamHorse = { -362.0, 784.8, 117.3 }
Config.Stables[1].CamHorseGear = { -362.0, 784.8, 117.3 }
Config.Stables[1].CamCart = { -363.58, 792.11, 118.04 }

-- Additional locations. Entrance/horse positions reference RSG Horses config.
-- Camera and wagon positions are initial placements; check terrain and clearance in-game.
local additionalStables = {
    {
        Name = 'Colter Stable',
        BlipIcon = 1938782895,
        EnterStable = { -1334.20, 2397.41, 307.21, 2.0 },
        StableNPC = { -1334.20, 2397.41, 306.21, 67.43 },
        SpawnHorse = { -1344.8345, 2392.2900, 306.7908, 153.3136 },
        CamHorse = { -1339.0, 2393.6, 308.4 },
        CamHorseGear = { -1339.0, 2393.6, 308.4 },
        SpawnCart = { -1344.0, 2405.0, 307.0, 90.0 },
        CamCart = { -1336.0, 2405.0, 310.0 },
    },
    {
        Name = 'Van Horn Stable',
        BlipIcon = 1938782895,
        EnterStable = { 2968.86, 792.97, 51.40, 2.0 },
        StableNPC = { 2968.86, 792.97, 50.40, 357.89 },
        SpawnHorse = { 2970.4155, 785.6143, 51.3995, 137.7870 },
        CamHorse = { 2976.2, 786.8, 53.0 },
        CamHorseGear = { 2976.2, 786.8, 53.0 },
        SpawnCart = { 2980.0, 795.0, 51.4, 0.0 },
        CamCart = { 2988.0, 795.0, 54.4 },
    },
    {
        Name = 'Emerald Ranch Stable',
        BlipIcon = 1938782895,
        EnterStable = { 1393.46, 353.09, 87.63, 2.0 },
        StableNPC = { 1393.90, 354.29, 86.66, 151.53 },
        SpawnHorse = { 1396.73, 345.73, 87.58, 58.91 },
        CamHorse = { 1398.0, 351.5, 89.2 },
        CamHorseGear = { 1398.0, 351.5, 89.2 },
        SpawnCart = { 1404.0, 341.0, 87.6, 90.0 },
        CamCart = { 1404.0, 349.0, 90.6 },
    },
    {
        Name = 'Scarlett Meadows Stable',
        BlipIcon = 1938782895,
        EnterStable = { 1211.55, -190.84, 101.39, 2.0 },
        StableNPC = { 1211.55, -190.84, 100.39, 100.22 },
        SpawnHorse = { 1215.1134, -207.5254, 101.0958, 267.8741 },
        CamHorse = { 1215.0, -201.5, 102.7 },
        CamHorseGear = { 1215.0, -201.5, 102.7 },
        SpawnCart = { 1224.0, -207.0, 101.1, 270.0 },
        CamCart = { 1224.0, -199.0, 104.1 },
    },
}
for _, stable in ipairs(additionalStables) do
    Config.Stables[#Config.Stables + 1] = stable
end
