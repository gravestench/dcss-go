local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.mindburst")
local spells = require("ids.spells")

local mindburst = {}
-- Mindburst rejects brainless monsters before its mental damage rule resolves the hex.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_MINDBURST)

-- Example: mindburst.plan(ctx, caster, foe) with brainless monster -> nil plan
-- Excludes brainless targets before mental damage.
function mindburst.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The mental damage rule runs only for a viable, non-brainless defender.
function mindburst.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return mindburst
