# Portal Follower Transit Design

## Intent

Apply the existing source-style monster follower wave to accepted portal
travel. The pinned source tags the wave before monster decisions, then admits
ordinary followers when the **destination** branch allows them: connected
branches and Pandemonium. Temporary isolated branches reject ordinary
followers. The same Akara entity, carried items, statuses, and AI move to a
free destination cell; a failed landing leaves the monster on its source
floor. All temporary marks disappear before a completed action or save.
The actor retains its first spawn branch as durable ECS provenance, so a
save validates its roster against that branch even after a Pan source floor
has been retired.

## Ownership and transaction

Lua `policy.world.stair_followers` remains the one owner of selection,
branch eligibility, destination placement, transfer, and mark cleanup. A
prepared user portal flags its accepted action for tagging. The generic Go
portal transaction calls one Lua arrival policy after its own Lua commit and
before retiring an old floor. Errors use the existing step checkpoint and
rollback. Forced portal moves do not acquire a wave. Ordinary stone stairs
also use the destination branch gate, matching the same source rule.

## Scope and evidence

Exercise both a connected or Pan portal and a temporary isolated portal
through actual `Game.Step`, including a carried item and save/restore.
Source's Hepliaklqana ancestor exception remains with that unported
religion actor domain; this slice must not synthesize an ancestor or allow
unrelated monsters into isolated portals.
