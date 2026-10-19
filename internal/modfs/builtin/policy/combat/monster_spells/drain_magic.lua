local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.drain_magic")
local spells = require("ids.spells")

local drain = {}
-- Drain Magic routes the hit through a hex rule that drains MP and can heal a ghost moth caster.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_DRAIN_MAGIC)

-- Example: drain.plan(ctx, caster, foe) with foe with MP -> entity plan for later MP drain
-- Lets a ghost moth's successful hex drain MP and heal it.
function drain.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The hex rule drains MP and may heal a ghost moth only on a landed effect.
function drain.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return drain
