# Transporter Follower Parity Design

## Intent

Bring ordinary transporter followers into the same source-style follower
wave as stairs. The transporter already carries nearby actors, but its
current ECS-query scan can choose a different set and order from the
source's connected wave. The shared rule should be readable in one Lua
owner, while stair marking and same-floor movement remain distinct.

## Source behavior

`handle_followers` walks eight-neighbor connected actors from the player's
departure cell. An adjacent nonfriendly actor reduces the maximum radius
from five to one. The 18-follower limit counts successful transfers. Both
travel modes require a living, active, mobile actor with at least 50 energy,
ordinary-floor habitat, and an appropriate pursuit or friendly stance.
Unfriendly actors must be adjacent and pursuing the player. A transporter
accepts body types that ordinary stairs reject, except tentacles and their
segments. It can also carry a summon because the source's summon exclusion
belongs to stair use. An actor unable to find a safe destination can still
connect the wave, although it does not consume the transfer allowance.

## Ownership

`policy.world.follower_wave` owns the deterministic neighbor order,
connected search, range rule, and 18-result cap. The shared eligibility
module owns living/active/attitude checks and applies the appropriate
body gate for `stairs` or `transporter`. The existing stair policy uses the
wave before setting one-action marks and applying twin pairing. The
transporter policy uses it after moving the player, relocating selected
actors on the same floor without durable marks. Akara entity identity and
carried state remain untouched.

## Verification

Lua tests should show an energy-starved, paralysed, sleeping, or unrelated
hostile actor stays behind; summons and ordinarily non-climbing bodies may
follow a transporter; tentacles do not. They should show a disconnected
friendly actor cannot follow, an adjacent hostile limits the friendly
radius, the wave selects by position rather than ECS query order, and the
source's 18-transfer limit. Existing stair and transporter game tests plus
the Go build guard integration. A full destination leaves followers safely
on the source side and does not roll back the player's passage.
