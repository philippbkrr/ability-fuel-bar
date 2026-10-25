--[[
    AbilityFuelBar - Configuration
    ===============================
    All values can be changed freely. No restart of the resource is needed
    for most changes, but a restart is recommended after editing.
]]

Config = {}

-- How often (in seconds) the bar is refreshed while driving.
-- 0.1 = 10x per second (smooth). Increase if you see performance issues.
Config.UpdateInterval = 0.1

-- Vehicle classes that have NO fuel tank (bar is hidden).
-- https://docs.fivem.net/natives/?_0x29439776AAA00A62 (GetVehicleClass)
Config.ExcludedClasses = {
    [13] = true, -- Bicycle
    [14] = true, -- Boat
    [15] = true, -- Helicopter
    [16] = true, -- Plane
    [21] = true, -- Train
    -- NOTE: class 8 (Motorcycle) is NOT excluded because LegacyFuel gives
    -- motorcycles a fuel tank (Config.Classes[8] = 1.0).
    -- NOTE: class 22 (Submarine) is NOT excluded because Formula/Open Wheel
    -- race cars (formula, formula2, openwheel1, openwheel2) report class 22
    -- via GetVehicleClass even though they have a fuel tank.
}

-- Vehicle classes that ALWAYS have a fuel tank.
-- Used to decide whether to show the bar when no fuel script is detected.
Config.FueledClasses = {
    [0]  = true, -- Compacts
    [1]  = true, -- Sedans
    [2]  = true, -- SUVs
    [3]  = true, -- Coupes
    [4]  = true, -- Muscle
    [5]  = true, -- Sports Classics
    [6]  = true, -- Sports
    [7]  = true, -- Super
    [9]  = true, -- Off-Road
    [10] = true, -- Industrial
    [11] = true, -- Utility
    [12] = true, -- Vans
    [17] = true, -- Trailer
    [18] = true, -- Trailer
    [19] = true, -- Trailer
    [20] = true, -- Trailer
}

-- If true: only show the bar when a supported fuel script was detected.
-- If false: always show the bar (uses the native GetVehicleFuelLevel as source).
Config.RequireFuelScript = false

-- If true, the bar is hidden while the player is in a vehicle that is
-- currently being refueled (e.g. at a gas station). Requires the fuel script
-- to expose a "refueling" state; otherwise this has no effect.
Config.HideWhileRefueling = false

-- Fuel alerts (native, unobtrusive: a UI sound only).
Config.EnableAlerts = true
Config.AlertSound = "5_Second_Timer"
Config.AlertSoundSet = "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS"
Config.MinThreshold = 1 -- lowest mark that alerts (1% is the last)

-- Normal alert: fires every NormalStep marks while fuel is ABOVE
-- FrequentStepThreshold. e.g. NormalStep=10, FrequentStepThreshold=10
-- -> alerts at 90, 80, 70, ..., 20.
Config.NormalStep = 10

-- Below this fuel value, alerts become MORE frequent (FrequentStep).
Config.FrequentStepThreshold = 10

-- Below FrequentStepThreshold, alerts fire every FrequentStep marks.
-- e.g. FrequentStep=1 -> alerts at 10, 9, 8, ..., 1.
Config.FrequentStep = 1
