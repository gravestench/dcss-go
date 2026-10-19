-- Malmutate uses a non-damaging beam so walls, intervening actors, and
-- reflection follow the same source ray rules as other monster hexes.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.malmutate")
local spells = require("ids.spells")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_MALMUTATE)

-- Skip targets the source says cannot mutate before committing an intent.
function effect.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- Recheck the contacted actor after tracing, then write the mutation to
-- its existing saved component owner.
function effect.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return effect
