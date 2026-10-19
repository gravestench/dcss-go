local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.agony")
local spells = require("ids.spells")

local agony = {}
-- Agony delegates torment eligibility and HP loss to its hex rule after the shared monster hex check.
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_AGONY)

-- Example: agony.plan(ctx, caster, foe) with torment-immune foe -> nil plan
-- Checks Agony's torment eligibility before the hex rule can halve HP.
function agony.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- Resolve saved foe through the Agony rule so torment resistance precedes HP loss.
function agony.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return agony
