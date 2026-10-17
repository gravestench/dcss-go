local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local steam_ball = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STEAM_BALL)

function steam_ball.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function steam_ball.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return steam_ball
