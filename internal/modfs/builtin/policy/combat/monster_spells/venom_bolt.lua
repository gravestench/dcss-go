local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local poison = require("policy.combat.monster_beams.poison")
local spells = require("ids.spells")

local venom_bolt = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_VENOM_BOLT)

function venom_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function venom_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, poison)
end

return venom_bolt
