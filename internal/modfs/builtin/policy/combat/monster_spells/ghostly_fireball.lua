local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local draining = require("policy.combat.monster_beams.draining")
local spells = require("ids.spells")

local ghostly_fireball = {}
-- Ghostly Fireball uses an explosive beam profile with negative-energy flavour.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_GHOSTLY_FIREBALL)

-- Example: ghostly_fireball.plan(ctx, caster, foe) with reachable foe -> cell plan for a negative-energy blast
-- Targets a blast with negative-energy flavour.
function ghostly_fireball.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Expand the endpoint with negative-energy flavour from the ghostly profile.
function ghostly_fireball.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, draining)
end

return ghostly_fireball
