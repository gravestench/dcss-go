local cancellation = require("policy.potions.cancellation")
local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_enchant = require("policy.combat.monster_enchant")

local quicksilver = {}

-- beam.cc:bolt::affect_player and bolt::affect_monster call the same
-- debuff rules as cancellation after the physical hit.
function quicksilver.after_hit(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        cancellation.purge(ctx, defender)

        return
    end

    local actor = ctx:get(defender, component.ACTOR)

    if not actor then
        error("quicksilver defender has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)

    monster_enchant.dispel(ctx, defender, definition)
end

return quicksilver
