# cheese-tide-rush

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/deranalabs/cheese-tide-rush/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/deranalabs/cheese-tide-rush/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Cheese Tide Rush is a Roblox brainrot tycoon set in a neon harbour at dusk: buy absurd characters off a market conveyor, walk them home to your dock and watch them earn cash every second. Every 45 to 60 seconds a glowing wall of neon cheese sweeps the harbour, a Night Gull Raider comes for your weakest brainrot, and other players can steal anything you have not locked behind your laser gate.

## Run it

```sh
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

This copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` into `out/` and writes `out/dossier.json`. To rebuild the place from source: `rojo build default.project.json --output game.rbxl`.

## How to play

- Walk to the market lane and hold **E** on a brainrot to buy it; it follows you home and drops into your next free slot.
- Each brainrot earns its `$X/s` into your cash pad; stand on the green pad to collect.
- 28 characters over 7 rarities (Common to Brainrot God), plus Gold x2, Diamond x3, Toxic x4 and Rainbow x5 mutations.
- When the siren sounds, get onto any base: the Cheese Tide washes away every brainrot you are still carrying.
- Press **L** (or the red button on your dock) to raise a laser gate for 60 s; it blocks stealing and the raider, then recharges.
- Chase the Night Gull Raider and press **B** to bonk it, which rescues your brainrot and pays a reward.
- Buy Speed, Slot (6 to 10) and Lock Time upgrades; Rebirth resets cash and brainrots for a permanent income multiplier and a new title.

## How it is built

All game logic lives in `src/` and is built into `game.rbxl` with Rojo. The server owns all state; the client only renders it and sends requests.

- `src/shared/Config.luau`: every tuning constant.
- `src/shared/Rarity.luau`: the rarity ladder and the mutations.
- `src/shared/Cast.luau`: the 28 characters, their looks, income and prices.
- `src/shared/Format.luau`: short money strings.
- `src/shared/Net.luau`: the RemoteEvents both sides share.
- `src/server/Main.server.luau`: boot order, player join and leave, request routing, state sync.
- `src/server/PlayerState.luau`: the single home of each player's state.
- `src/server/WorldBuilder.luau`: builds the harbour, market lane, 8 docks and props at runtime.
- `src/server/BrainrotFactory.luau`: builds each character from Parts, with face, sparkle and label.
- `src/server/Market.luau`: the conveyor and buying.
- `src/server/Carry.luau`: brainrots following you home and dropping into slots.
- `src/server/Base.luau`: dock ownership, safe zones, slots and gate visuals.
- `src/server/Economy.luau`: per-second income and the cash pad.
- `src/server/Steal.luau`: stealing and the timed base lock.
- `src/server/Raider.luau`: the Night Gull Raider.
- `src/server/Tide.luau`: the Cheese Tide sweep and siren.
- `src/server/Upgrades.luau`: Speed, Slot and Lock Time upgrades.
- `src/server/Rebirth.luau`: rebirths, multipliers and titles.
- `src/client/Hud.client.luau`: cash, income, buttons and toasts.
- `src/client/Input.client.luau`: the L key, and hides steal prompts on your own brainrots.
- `src/client/WorldFx.client.luau`: tide banner, screen flash and shake, and the Rainbow shimmer.

<sub>Entered on [make.fun](https://make.fun/?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
