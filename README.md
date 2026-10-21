# PC Builder Tycoon — v1 (MVP)

This is a working core loop: **buy parts → assemble a PC → clients message you
with jobs → deliver builds that meet their specs → earn cash → repeat.**
Room-building is intentionally left out of v1 so we can get the hustle loop
solid first, then layer the room/aesthetic side on top.

## What's in this pack

| File | Where it goes in Roblox Studio | Type |
|---|---|---|
| `ReplicatedStorage_PCPartsData.lua` | `ReplicatedStorage` → rename to `PCPartsData` | ModuleScript |
| `ReplicatedStorage_RequestsData.lua` | `ReplicatedStorage` → rename to `RequestsData` | ModuleScript |
| `ServerScriptService_Main.lua` | `ServerScriptService` → rename to `Main` | Script |
| `StarterPlayerScripts_ClientUI.lua` | `StarterPlayer > StarterPlayerScripts` → rename to `ClientUI` | LocalScript |

## Setup steps (5 minutes)

1. Open Roblox Studio, create a new **Baseplate** place (or use your existing one).
2. In the Explorer:
   - Right-click **ReplicatedStorage** → Insert Object → **ModuleScript**. Paste in the contents of `ReplicatedStorage_PCPartsData.lua`, rename it `PCPartsData`.
   - Do the same for `ReplicatedStorage_RequestsData.lua` → `RequestsData`.
   - Right-click **ServerScriptService** → Insert Object → **Script**. Paste `ServerScriptService_Main.lua`, rename it `Main`.
   - Right-click **StarterPlayer > StarterPlayerScripts** → Insert Object → **LocalScript**. Paste `StarterPlayerScripts_ClientUI.lua`, rename it `ClientUI`.
3. **Turn on DataStores in Studio** (or saving won't work while testing):
   `Home` tab → `Game Settings` → `Security` → enable **"Enable Studio Access to API Services"**.
4. Press **Play**. You should see a panel at the bottom-center with **Shop / My Build / Requests** tabs.

## How the loop works right now

- Everyone starts with $200 and the free ("budget") part in every category.
- **Shop tab**: buy better CPU/GPU/RAM/Case/RGB parts, then hit **Equip** to put them in your current build.
- **My Build tab**: shows your current Power and Style totals.
- **Requests tab**: a random client messages you (auto-triggers ~5 seconds after joining, and again a few seconds after you deliver one). Each request needs a minimum Power and/or Style score. Hit **Deliver Build** — if your currently equipped parts meet the bar, you get paid and a new request comes in.
- Progress (cash + owned parts + equipped build) autosaves every 2 minutes and on leave.

## Known intentional simplifications (v1)

- No 3D PC model or room yet — this is the economy/loop skeleton so we can validate it's fun before investing in art/animation.
- Only one active request at a time, no request queue/expiry timer yet.
- No monetization (Robux products) wired up yet.

## Natural next steps, in order I'd suggest tackling them

1. **Playtest the loop** — is buying/equipping/delivering satisfying on its own, before any art exists?
2. **3D PC model** — swap parts visually (different case meshes, GPU with light-up textures, RGB emitting `PointLight`/`SurfaceLight` instances) so "equip" actually changes what your character sees.
3. **Room building** — a separate build-mode where players place furniture/wall colors/LED strips from an inventory, similar structure to the parts system here (a `RoomItemsData` module + placement remotes).
4. **Request variety/expiry** — timers, a queue of 2-3 requests at once, occasional "VIP" clients with huge rewards but tight requirements.
5. **Monetization** — Developer Products for "rush order" (skip the 5s cooldown), cosmetic-only RGB/case skins as Robux purchases, a "double cash" gamepass.
6. **Social hook** — a "showroom" server or plot where players can walk through builds/rooms other players made, since showing off drives shares (this is the single biggest viral lever based on what's working on Roblox right now).

Bring this back any time you want to add room-building, a real 3D part-swapping system, or monetization, and we'll build the next layer on top of this same structure.
