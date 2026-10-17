local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local sleep_rule = require("policy.combat.monster_beams.sleep")
local spells = require("ids.spells")

local sleep = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SLEEP)

function sleep.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function sleep.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, sleep_rule)
end

return sleep
