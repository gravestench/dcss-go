local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.virulence")
local spells = require("ids.spells")

local virulence = {}
-- Virulence skips fully poison-resistant targets before adding vulnerability through its hex rule.
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_VIRULENCE)

-- Example: virulence.plan(ctx, caster, foe) with fully poison-immune foe -> nil plan
-- Excludes fully poison-resistant defenders.
function virulence.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The rule adds poison vulnerability only after viable-target and hex checks.
function virulence.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return virulence
