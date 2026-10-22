-- Theory of operation: the source Royal Jelly carries a death callback.
-- Its original vault identity, saved on the actor, releases the Slime Pit
-- clear stone walls even if the monster moved or changed shape first.
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local monsters = require("ids.monsters")
local names = require("constants.slime_pit")
local seals = require("policy.world.slime_seals")

local slime_pit = {}

-- One original monster can release each cell only once. Keep marker
-- entities after the wall falls so the event remains auditable in saves.
function slime_pit.on_death(ctx, monster)
    local origin = ctx:get(monster, component.VAULT_ORIGIN)

    if not origin or origin.vault_id ~= names.MAP_ID or
        origin.kind_id ~= monsters.MONS_ROYAL_JELLY or
        origin.occurrence ~= 1 then
        return false
    end

    local found = seals.release(ctx, origin.level_id)

    if found == 0 then
        error("the Royal Jelly has no saved Slime Pit seal")
    end

    return false
end

death_hooks.add("slime_pit.royal_jelly", slime_pit.on_death)

return slime_pit
