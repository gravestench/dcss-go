local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.agony")
local spells = require("ids.spells")

local agony = {}
-- Ranged Agony has a separate catalog profile but shares ordinary Agony's torment rule.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_AGONY_RANGE)

-- Example: agony.plan(ctx, caster, foe) with susceptible foe in range -> entity plan for ranged Agony
-- Uses the ranged profile while retaining the ordinary Agony HP rule.
function agony.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- Reuse the ranged profile but retain the same torment HP rule as adjacent Agony.
function agony.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return agony
