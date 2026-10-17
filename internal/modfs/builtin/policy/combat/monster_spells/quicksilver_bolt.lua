local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local quicksilver = require("policy.combat.monster_beams.quicksilver")
local spells = require("ids.spells")

local quicksilver_bolt = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_QUICKSILVER_BOLT)

function quicksilver_bolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function quicksilver_bolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, quicksilver)
end

return quicksilver_bolt
