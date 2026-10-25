--[[
    AbilityFuelBar
    ==============
    Uses the native Special Ability bar (the orange bar under the minimap,
    normally used for the character's special ability) as a fuel gauge.

    When you enter a vehicle, the bar appears and shows the current fuel
    level. When you exit, the bar disappears.

    Compatible with the most popular fuel scripts:
      - LegacyFuel, qb-fuel, ps-fuel, cdn-fuel, Vanaheim Fuel
        (all register themselves as "LegacyFuel" with GetFuel/SetFuel)
      - ox_fuel (Statebag: Entity(vehicle).state.fuel)
      - Any script that sets the native fuel level (GetVehicleFuelLevel)

    Framework-independent (ESX, QBCore, QBox, Standalone).

    License: MIT - free to use and modify.
]]

local playerPed = PlayerPedId
local currentVehicle = 0
local currentClass = nil -- cached vehicle class (set on vehicle change)
local lastThreshold = 100
local justEntered = false
local fuelSource = nil -- 'export' | 'statebag' | 'native' | nil
local fuelExport = nil -- cached LegacyFuel export function
local fuelExportSelf = nil -- cached LegacyFuel export table (self)
local minimap = nil

-- Detects which fuel source is available on this server.
-- Priority: export (LegacyFuel-style) > statebag (ox_fuel) > native.
-- Caches the export function so getFuelLevel does not re-resolve it every frame.
local function detectFuelSource()
    local ok = pcall(function()
            fuelExport = exports['LegacyFuel'].GetFuel
            fuelExportSelf = exports['LegacyFuel']
        end)
    if ok and fuelExport then
        return 'export'
    end
    return 'native'
end

-- Reads the fuel level (0-100) from the detected source.
local function getFuelLevel(vehicle)
    if fuelSource == 'export' then
        local ok, fuel = pcall(fuelExport, fuelExportSelf, vehicle)
        if ok and type(fuel) == 'number' then
            return fuel
        end
        fuelSource = 'native'
    end

    if fuelSource == 'statebag' then
        local fuel = Entity(vehicle).state.fuel
        if type(fuel) == 'number' then
            return fuel
        end
        fuelSource = 'native'
    end

    local fuel = GetVehicleFuelLevel(vehicle)
    if type(fuel) == 'number' then
        return fuel
    end
    return 100 -- nil-safe fallback
end

-- Returns the alert step for a fuel level: FrequentStep marks below
-- FrequentStepThreshold, NormalStep marks above it.
local function getThreshold(fuel)
    if fuel < Config.FrequentStepThreshold then
        return math.floor(fuel / Config.FrequentStep) * Config.FrequentStep
    end
    return math.ceil(fuel / Config.NormalStep) * Config.NormalStep
end

-- Shows the ability bar and fills it to the given fuel value (0-100).
-- Drives the minimap Scaleform DIRECTLY (the Cfx forum solution). The native
-- SetAbilityBarValue gets overwritten by the game's special-ability logic
-- (the blue flicker), but the Scaleform calls cannot be overwritten.
local function showAbilityBar(fuel)
    SetAllowAbilityBarInMultiplayer(true)
    BeginScaleformMovieMethod(minimap, "SET_ABILITY_BAR_VISIBILITY_IN_MULTIPLAYER")
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()
    BeginScaleformMovieMethod(minimap, "SET_ABILITY_BAR")
    ScaleformMovieMethodAddParamInt(math.floor(fuel))
    EndScaleformMovieMethod()
    BeginScaleformMovieMethod(minimap, "SET_ABILITY_BAR_VISIBLE")
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()
end

-- Hides the ability bar. SetAllowAbilityBarInMultiplayer(false) forbids the
-- bar in multiplayer entirely, so the blue special-ability bar cannot show
-- while on foot. The Scaleform calls then hide the slot.
local function hideAbilityBar()
    SetAllowAbilityBarInMultiplayer(false)
    BeginScaleformMovieMethod(minimap, "SET_ABILITY_BAR_VISIBILITY_IN_MULTIPLAYER")
    ScaleformMovieMethodAddParamBool(false)
    EndScaleformMovieMethod()
    BeginScaleformMovieMethod(minimap, "SET_ABILITY_BAR_VISIBLE")
    ScaleformMovieMethodAddParamBool(false)
    EndScaleformMovieMethod()
end

-- Alert: a clear UI sound. (Sound only — no bar flashing.)
local function alert()
    PlaySoundFrontend(-1, Config.AlertSound, Config.AlertSoundSet, true)
end

-- Returns true if the vehicle should show the fuel bar.
-- Uses the cached vehicle class (set on vehicle change).
local function shouldShowBar()
    if currentClass and Config.ExcludedClasses[currentClass] then
        return false
    end
    if Config.RequireFuelScript and fuelSource == 'native' then
        return false
    end
    return true
end

-- Main loop: detects vehicle changes and updates the bar.
CreateThread(function()
    fuelSource = detectFuelSource()

    -- Load the minimap Scaleform so we can drive the ability bar directly.
    minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)

    while true do
        local ped = playerPed()
        -- Robust vehicle detection: GetVehiclePedIsIn can return 0 for some
        -- vehicles (e.g. Open Wheel race cars). Fall back to the closest
        -- vehicle within 5m.
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 and IsPedInAnyVehicle(ped, false) then
            -- GetVehiclePedIsIn returns 0 for some vehicles (e.g. Open Wheel
            -- race cars). Fall back to the closest vehicle within 5m.
            local coords = GetEntityCoords(ped)
            vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)
        end
        if vehicle ~= currentVehicle then
            -- Vehicle changed (entered or exited)
            currentVehicle = vehicle
            currentClass = (vehicle ~= 0) and GetVehicleClass(vehicle) or nil
            lastThreshold = 100
            justEntered = true

            -- Detect ox_fuel statebag on this vehicle, if present
            if vehicle ~= 0 and fuelSource == 'native' and type(Entity(vehicle).state.fuel) == 'number' then
                fuelSource = 'statebag'
            end
        end

        if vehicle == 0 then
            -- Not in a vehicle: fully deactivate + lock the special ability so
            -- GTA cannot show the blue bar while on foot. Re-asserted every
            -- frame because the game re-enables it otherwise.
            SpecialAbilityDeactivateFast(playerPed())
            SpecialAbilityDeactivate(playerPed())
            EnableSpecialAbility(playerPed(), false)
            SpecialAbilityLock(GetEntityModel(playerPed()))
            hideAbilityBar()
            lastThreshold = 100
        elseif shouldShowBar() then
            local fuel = getFuelLevel(vehicle)

            -- Bar display: always show the fuel value (no blinking).
            showAbilityBar(fuel)

            -- Step alerts (sound only): NormalStep marks above the threshold,
            -- FrequentStep marks below it.
            if Config.EnableAlerts then
                local threshold = getThreshold(fuel)
                if justEntered then
                    -- First frame after entering: sync the threshold, no alert.
                    lastThreshold = threshold
                    justEntered = false
                elseif threshold < lastThreshold then
                    if threshold >= Config.MinThreshold then
                        alert()
                    end
                    lastThreshold = threshold
                elseif threshold > lastThreshold then
                    -- Fuel rising again: reset so the next drop re-alerts.
                    lastThreshold = threshold
                end
            end
        else
            hideAbilityBar()
        end

        Wait(Config.UpdateInterval * 1000)
    end
end)
