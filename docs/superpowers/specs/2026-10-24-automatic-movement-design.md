# Automatic Movement Design

## Goal

Implement the ordinary DCSS automatic movement command family: eight
shift-run directions, long rest on `5`, and autoexplore on `o`. A run must
stop before stepping into a newly seen monster, cloud, changed feature, or
blocked square. Rest waits for recoverable HP/MP and then ends; starting
at full resources performs the source's 100-turn long wait. Autoexplore
walks toward the nearest reachable unexplored frontier and stops when no
frontier remains. Any key interrupts without spending another turn.

## Ownership

Lua `policy.input.automation` owns key routing, next-step choice, stop
conditions, and pathfinding over the visible and remembered floor. The
terminal app owns a temporary Tea timer and a compact automation state;
each tick asks Lua for the next ordinary game command, then calls the
existing `Game.Step` path. No movement or combat rule is reimplemented in
Go, and automation state does not enter saves. The game view provides only
player-observable feature IDs and monster allegiance; unknown cells stay
unknown. The policy uses the same command IDs and direction constants as
ordinary movement input.

## Source basis and practical boundary

Pinned source `cmd-keys.h` maps `B H J K L N U Y`, shifted cursor keys,
`5`, and `o`. `travel.cc` records forward and flank feature classes for
shift-run, checks clouds and monsters, and stops on interruption. `main.cc`
chooses rest versus a 100-turn wait from current recovery. `player.cc`
ends rest when recoverable HP and MP reach their full threshold. This port
will preserve those visible decisions. Travel exclusions, custom rc
interrupt settings, and greedy item detours remain separate option/UI
domains; they should not be simulated with hidden Go state here.

## Verification

Lua tests exercise all key directions, changes to run flanks and forward
features, visible hostiles and clouds, rest/long-wait decisions, and
deterministic pathfinding from a remembered grid. Terminal tests verify
automatic ticks use real game steps and key interruption costs no turn.
The slice ends with focused suites, a build, one category commit, and push.
