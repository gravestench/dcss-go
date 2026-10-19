-- Monster Chain of Chaos selects a target after each jump and may strike
-- allies or revisit old targets. Its original caster is safe on a return
-- arc, but every other contacted actor draws a fresh Chaos flavour.
-- Source: mon-cast.cc and spl-damage.cc:cast_chain_spell.
-- Example: a hostile caster with a visible foe plans a self-centered cast;
-- the chain then finds its actual first victim at resolution time.
local actors = require("policy.combat.monster_area.actors")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local chain = require("policy.combat.monster_area.chain_of_chaos")
local impact = require("policy.combat.monster_area.chaos_impact")
local power = require("policy.combat.monster_beams.power")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}
local SIGHT_RADIUS = 7
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CHAIN_OF_CHAOS)

-- Source AI declines a visible allied cast. Other casters only need one
-- possible enemy in sight; the actual arc may hit another closer actor.
function effect.plan(ctx, caster)
    if targets.allied(ctx, caster) and
        senses.player_sees_actor(ctx, caster) then
        return nil
    end

    for _, victim in ipairs(actors.los(ctx,
        caster, SIGHT_RADIUS)) do
        if targets.enemy(ctx, caster, victim) then
            return self_target.plan(caster)
        end
    end

    return nil
end

-- The self target is a casting intent, not a fixed impact point. Resolve
-- each live jump using its current attenuated power and per-cell flavour.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local spell_power = power.caster_power(ctx,
        caster, profile)

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit("spell", "A swirling arc of seething chaos appears!")
    end

    chain.resolve(ctx, caster, spell_power, function(context,
        source, target, arc_power, visual)
        impact.apply(context, caster, source, target,
            arc_power, visual)
    end, streams.MONSTER_SPELL)
end

return effect
