local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local fireball = {}
-- Fireball is an explosion profile; beam resolution expands the endpoint rather than piercing actors.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FIREBALL)

-- Example: fireball.plan(ctx, caster, foe) with reachable foe -> cell plan for the later blast
-- Chooses the endpoint later expanded into blast cells.
function fireball.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Expand the saved endpoint into blast cells instead of treating the spell as piercing.
function fireball.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return fireball
