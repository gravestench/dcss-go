local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.polymorph")
local spells = require("ids.spells")

local polymorph = {}
-- Polymorph first checks whether the defender can change form, then delegates the change to its hex rule.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_POLYMORPH)

-- Example: polymorph.plan(ctx, caster, foe) with untransformable foe -> nil plan
-- Excludes defenders whose form cannot change.
function polymorph.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- After viability and resistance, the rule changes the defender's form.
function polymorph.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return polymorph
