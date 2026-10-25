# AbilityFuelBar

Uses the native **Special Ability bar** (the orange bar under the minimap, normally used for the character's special ability) as a **fuel gauge**.

When you enter a vehicle, the bar appears and shows the current fuel level. When you exit, the bar disappears. No UI elements, no NUI, no dependencies — it reuses a bar that is already part of the game.

## Features

- 🚗 Shows the fuel level in the native ability bar while driving
- 🚪 Bar appears on vehicle entry, disappears on exit
- 🔔 Configurable fuel alerts: a native UI sound on fuel-level marks (ten-marks above a threshold, every step below it)
- 🔌 Works with the most popular fuel scripts (see below)
- 🧩 Framework-independent (ESX, QBCore, QBox, Standalone)
- ⚙️ Fully configurable via `config.lua`
- 🪶 Lightweight — a single client thread, no NUI, no HTML

## Compatibility

| Fuel script | Detection |
|---|---|
| LegacyFuel | `exports['LegacyFuel']:GetFuel` |
| qb-fuel | `exports['LegacyFuel']:GetFuel` |
| ps-fuel | `exports['LegacyFuel']:GetFuel` |
| cdn-fuel | `exports['LegacyFuel']:GetFuel` |
| Vanaheim Fuel | `exports['LegacyFuel']:GetFuel` |
| ox_fuel | Statebag `Entity(vehicle).state.fuel` |
| Any script using the native | `GetVehicleFuelLevel` (fallback) |

If your fuel script is not listed, it likely still works via the native fallback — as long as it sets the vehicle's fuel level through the game native.

## Installation

1. Copy the `ability-fuel-bar` folder into your server's `resources` directory:
   ```
   resources/[local]/ability-fuel-bar/
   ```
2. Add it to your `server.cfg`:
   ```
   ensure ability-fuel-bar
   ```
3. Restart the server (or use txAdmin to start the resource).

## Configuration

Edit `config.lua`:

- `UpdateInterval` — how often the bar refreshes (seconds). Default `0.1`.
- `ExcludedClasses` — vehicle classes with no fuel tank (bar hidden). Defaults: bicycles, boats, helicopters, planes, trains. (Motorcycles and Formula/Open Wheel cars are NOT excluded — they have a fuel tank via LegacyFuel.)
- `FueledClasses` — vehicle classes that always have a fuel tank.
- `RequireFuelScript` — if `true`, only show the bar when a supported fuel script is detected.
- `HideWhileRefueling` — hide the bar while the vehicle is being refueled (requires the fuel script to expose a refueling state).

### Fuel alerts

- `EnableAlerts` — master switch for the alert sounds.
- `AlertSound` / `AlertSoundSet` — the native UI sound to play.
- `MinThreshold` — lowest fuel mark that alerts (default `1`).
- `NormalStep` — alert every N marks while fuel is above `FrequentStepThreshold` (default `10` → 90, 80, ..., 20).
- `FrequentStepThreshold` — below this fuel value, alerts become more frequent (default `10`).
- `FrequentStep` — alert every N marks below `FrequentStepThreshold` (default `1` → 10, 9, 8, ..., 1).

## How it works

The script detects the fuel source in this order:

1. **Export** — if a script registered itself as `LegacyFuel` (LegacyFuel, qb-fuel, ps-fuel, cdn-fuel, Vanaheim), it uses `exports['LegacyFuel']:GetFuel(vehicle)`.
2. **Statebag** — if the vehicle has a `fuel` statebag (ox_fuel), it reads `Entity(vehicle).state.fuel`.
3. **Native** — falls back to `GetVehicleFuelLevel(vehicle)`.

The bar is driven directly through the minimap Scaleform (`SET_ABILITY_BAR_VISIBILITY_IN_MULTIPLAYER`, `SET_ABILITY_BAR`, `SET_ABILITY_BAR_VISIBLE`), which the game's own special-ability logic cannot overwrite — this avoids the yellow/blue flicker that the native ability-bar API causes.

## License

MIT — free to use, modify and redistribute. Credit is appreciated but not required.
