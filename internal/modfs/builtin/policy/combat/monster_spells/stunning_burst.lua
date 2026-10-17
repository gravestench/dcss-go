local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")
local stun = require("policy.combat.monster_beams.stun")

local stunning_burst = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STUNNING_BURST)

function stunning_burst.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function stunning_burst.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, stun)
end

return stunning_burst
