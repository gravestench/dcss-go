local catalog = require("policy.catalog")
local component = require("constants.component")
local enchantment = require("policy.combat.monster_spells.hex")
local monster_form = require(
    "policy.magic.effects.statuses.polymorph")
local player_form = require("policy.magic.effects.forms.player")
local streams = require("constants.rng_streams")

local polymorph = {}

-- Example: polymorph.viable(ctx, nil, defender) with untransformable monster -> false viability
-- Reject defenders whose body or current state cannot produce a valid transformed actor.
function polymorph.viable(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        return player_form.can_polymorph(ctx, defender)
    end

    return monster_form.can_actor(ctx, defender)
end

-- Source: beam.cc:BEAM_POLYMORPH. The common hook already checked will.
function polymorph.apply(ctx, caster, defender, profile)
    if ctx:has(defender, component.PLAYER) then
        local power = enchantment.enchantment_power(ctx, caster, profile)

        player_form.polymorph(ctx, defender, power)

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    monster_form.shapeshift(ctx, defender, definition,
        streams.MONSTER_SPELL)
end

return polymorph
