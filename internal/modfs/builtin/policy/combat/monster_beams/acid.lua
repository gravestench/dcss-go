local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_enchant = require("policy.combat.monster_enchant")
local player_corrosion = require("policy.combat.player_corrosion")

local acid = {}

-- beam.cc:mons_adjust_flavoured and bolt::affect_player apply corrosion
-- after the ordinary acid hit. The status is stored on the defender.
function acid.before_damage(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        player_corrosion.apply(ctx, defender, 5)

        return
    end

    local actor = ctx:get(defender, component.ACTOR)

    if not actor then
        error("acid beam defender has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)

    monster_enchant.corrode(ctx, defender, definition)
end

return acid
