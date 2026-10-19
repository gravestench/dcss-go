local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.corona")
local spells = require("ids.spells")

local corona = {}
-- Corona skips already backlit targets before its rule writes the glowing status.
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_CORONA)

-- Example: corona.plan(ctx, caster, foe) with already backlit foe -> nil plan
-- Rejects an already backlit foe before adding a glow.
function corona.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The Corona rule writes glow only after the shared hex check passes.
function corona.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return corona
