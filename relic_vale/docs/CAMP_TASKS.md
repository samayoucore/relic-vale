# Camp task board

The board contains 12 visible contracts from 11 categories. The persistent cycle and seed vary duration and gold modestly; reopening the UI never rerolls offers. Accepting a contract replenishes that slot with a fresh stable contract ID while preserving the remaining offers. Refresh asks for confirmation and costs 5 Camp Gold; F7 offers a free debug refresh.

| Contract | Category | Camp level | Residents | Minimum resident level / skill | Base game hours | XP / Food / Materials / Gold |
|---|---|---:|---:|---|---:|---|
| Gather firewood | Logging | 1 | 1 | 1 / gathering 0 | 1.5 | 12 / 1 / 8 / 2 |
| Forage the meadow | Foraging | 1 | 1 | 1 / gathering 0 | 2 | 14 / 10 / 2 / 2 |
| Collect loose stone | Mining | 1 | 1 | 1 / mining 0 | 2.5 | 15 / 2 / 10 / 2 |
| Carry local supplies | Supply | 1 | 1 | 1 / trading 0 | 3 | 16 / 5 / 4 / 8 |
| Hunt woodland game | Hunting | 1 | 2 | 1 / hunting 1 | 5 | 25 / 20 / 4 / 8 |
| Salvage the old caravan | Salvage | 2 | 2 | 2 / scouting 2 | 7 | 35 / 5 / 28 / 12 |
| Trade with a neighboring village | Trading | 2 | 2 | 2 / trading 2 | 10 | 40 / 12 / 4 / 32 |
| Patrol the western road | Patrol | 2 | 2 | 2 / hunting 2 | 8 | 36 / 9 / 10 / 20 |
| Survey the distant hills | Exploration | 3 | 3 | 3 / scouting 3 | 24 | 70 / 24 / 35 / 35 |
| Work a rich ore seam | Mining | 3 | 3 | 3 / mining 3 | 18 | 60 / 8 / 60 / 20 |
| Help rebuild a hamlet bridge | Construction | 3 | 3 | 3 / gathering 3 | 30 | 90 / 35 / 50 / 65 |
| Escort the northern expedition | Special | 4 | 4 | 4 / scouting 4 | 48 | 120 / 60 / 90 / 90 |

The UI shows exact unmet camp level, facility, supply, mission-slot, worker-level and worker-skill requirements. Choose residents opens a picker with availability and the relevant skill. Server-side assignment repeats those checks, rejects duplicate/unknown workers and wrong party sizes, consumes task costs, marks every selected resident unavailable and records start/end game minutes. One to four residents are supported; starter forage/logging/stone/supply tasks require only one and no upfront supplies.

Mission time is (day−1)×1440 + minute from ValeLife. It progresses outdoors, in interiors and while the camp is unloaded, but not with wall-clock time while the application is closed. Workers visibly depart before being abstracted and return with supplies at completion. Resolution removes the pending record before granting rewards, records a bounded completion ledger, frees worker assignments and awards each worker XP. Worker level-ups improve skills. Saving after completion cannot replay the same reward; saving mid-task preserves its end time.

At upgrade_pending, mission Food/Materials/Gold and worker XP continue; Camp XP is discarded at its cap. No overflow survives a later upgrade. The final tier continues resource missions with no further camp level. Balance, costs, facilities, caps, offer durations, skill requirements and rewards are editable in data/camp.json.
