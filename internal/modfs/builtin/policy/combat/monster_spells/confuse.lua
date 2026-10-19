local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.confuse")
local spells = require("ids.spells")

local confuse = {}
-- The confusion rule applies different player and monster durations after shared hex resistance.
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_CONFUSE)

-- Example: confuse.plan(ctx, caster, foe) with viable foe -> entity plan for the confusion hex
-- Precedes separate player and monster confusion durations.
function confuse.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The hex rule chooses player or monster confusion duration after resistance.
function confuse.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return confuse
