local catalog = require("policy.catalog")
local component = require("constants.component")
local enchantment = require("policy.combat.monster_spells.hex")
local player_confusion = require("policy.magic.player_confusion")
local monster_confusion = require(
    "policy.magic.effects.statuses.confusing_touch")

local confuse = {}

-- Example: confuse.apply(ctx, caster, defender, profile) with player after failed save -> 5 to 7 turns of confusion
-- Source: beam.cc:BEAM_CONFUSION. The shared hex hook did the saving throw.
function confuse.apply(ctx, caster, defender, profile)
    if ctx:get(defender, component.PLAYER) then
        local turns = 5 + ctx:random("monster_spell", 3)

        player_confusion.extend(ctx, defender, turns)

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local power = enchantment.enchantment_power(ctx, caster, profile)

    monster_confusion.apply_unresisted(ctx, defender, definition, power)
end

return confuse
