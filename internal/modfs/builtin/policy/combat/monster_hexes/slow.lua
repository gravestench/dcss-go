local catalog = require("policy.catalog")
local component = require("constants.component")
local enchantment = require("policy.combat.monster_spells.hex")
local monster_slow = require("policy.combat.monster_slow")
local player_slow = require("policy.character.slow")

local slow = {}

-- Source: beam.cc:BEAM_SLOW; players gain 10 + random2(power) turns.
function slow.apply(ctx, caster, defender, profile)
    if ctx:get(defender, component.PLAYER) then
        local power = enchantment.enchantment_power(ctx, caster, profile)
        local turns = 10 + ctx:random("monster_spell", power)

        player_slow.apply(ctx, defender, turns)

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    monster_slow.apply(ctx, defender, definition)
end

return slow
