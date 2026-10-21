# PC Builder Tycoon (Roblox game, v1)

**A Roblox tycoon game about running a PC-building business: buy parts, build PCs, take jobs from clients who message you, and earn enough to afford better parts.**

> **Status: playable v1 prototype.** The core game loop works end to end and saves your progress. It doesn't have 3D PC models or room building yet. Those are next (see [What's next](#whats-next)).

I've built my own PCs in real life, so I wanted a game that captures the fun part: picking parts and showing off the build.

## How the game plays

```
Buy parts in the Shop ─► Equip them into your build ─► A client messages you with a job
        ▲                                                        │
        └──────────── get paid, buy better parts ◄── deliver a build that meets their specs
```

- **20 parts in 5 categories** (CPU, GPU, RAM, Case, RGB lighting), each with 4 tiers from free starter parts up to flagship parts like the "RTX Overkill 5090 Ti".
- **Two stats per build:** **Power** (CPU, GPU, RAM) and **Style** (case, RGB, plus a bit from the others).
- **Client jobs:** 8 different clients, each caring about power, style or both. For example, *"I need a PC for streaming, doesn't need to be crazy powerful but it HAS to look good on camera."* The required scores grow as you progress.
- **Saves your progress** (cash, owned parts, current build) automatically every 2 minutes and when you leave.

## How it's built

| File | Runs on | Job |
|---|---|---|
| `ReplicatedStorage_PCPartsData.lua` | Shared | Every part's name, price, Power and Style |
| `ReplicatedStorage_RequestsData.lua` | Shared | Client message templates |
| `ServerScriptService_Main.lua` | Server | Money, purchases, job checks, saving (DataStoreService), and the RemoteEvents the client talks to |
| `StarterPlayerScripts_ClientUI.lua` | Player | The Shop / My Build / Requests panel |

All money and job checks happen on the server, so players can't give themselves cash from their own client.

**Tech:** Lua (Luau) · Roblox Studio · DataStoreService · RemoteEvents

## What's next

v1 is the core money loop on purpose, so I can check it's fun before adding art. Planned next:

1. **3D PC model** where equipping a part visibly changes the PC (glowing GPU, RGB lights, different cases).
2. **Room building:** decorate your setup with furniture, wall colours and LED strips.
3. **More jobs:** several requests at once, timers, and rare "VIP" clients with big rewards.
4. **Showroom:** walk through other players' builds.
