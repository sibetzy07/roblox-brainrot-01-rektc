# Brainrot Rush — roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/sibetzy07/roblox-brainrot-01-rektc/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/sibetzy07/roblox-brainrot-01-rektc/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

A 3D Steal-a-Brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01),
built by an AI agent in a recorded session and laid out as a Rojo project. The player walks a 3D world: a
conveyor carries absurd meme brainrots west to east, the player claims them onto one of four base plots, and
each one earns money every second. Rarities run Common, Rare, Epic, Legendary, Mythic, Brainrot God, Secret,
with Gold, Diamond and Rainbow mutations multiplying income. Players steal from each other's unlocked bases
(a base lock holds for 30 seconds), a tsunami wave sweeps the map every 90 seconds and knocks a carried
brainrot out of your hands unless you dash home, and rebirths ($10,000 + 5 brainrots) and a shop (extra slots,
income boosts, a longer lock, faster walking) drive the climb.

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and
  `PLAY.json` to `/output`, leaving out every name that starts with a dot (such as `.gitkeep` or `.DS_Store`, which
  fail an entry), and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` (Luau) and `default.project.json`. The world is built at
  runtime by `src/server/WorldBuilder.luau` (conveyor, four bases, shop, spawn, decorations), and the game logic
  is split into modules with one job each: `BrainrotData` (cast, rarities, mutations), `GameState` (the single
  place all state lives), `Spawner`, `Income`, `Steal`, `Wave`, `Rebirth`, `Shop`, `Remotes`, with the client
  HUD and shop UI in `src/client/`.
- `screenshots/` holds four pictures of the game's own 3D world and characters, rendered from the same layout
  and cast the Luau server builds (`render_screenshots.py`, kept beside this repo in the entry folder). No
  Roblox Studio runs on the Linux machine that built this entry, so these are renders of the game's own world,
  not Studio captures; the thumbnail (`1-thumbnail.png`) is composed of the game's own world and characters.
  One of the screenshots must also be the game's first thumbnail on Roblox: the same picture, uploaded on the
  Creator Dashboard with the game's icon.
- `PLAY.json` names the published place: Brainrot Rush, place 102278090604356, universe 9469849250.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (https://make.fun/bounty/roblox-brainrot-01) and in the kit's RULES.txt,
which gives every command in order (Before you submit, then Enter).
