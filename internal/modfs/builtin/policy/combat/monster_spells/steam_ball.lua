local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local steam_ball = {}
-- Steam Ball traces as a steam beam, so the shared resolver may hit actors along its path.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STEAM_BALL)

-- Example: steam_ball.plan(ctx, caster, foe) with in-range foe -> entity plan for later steam trace
-- Saves the aim after checking that a steam ray reaches the foe safely.
function steam_ball.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Walk the steam ray so intermediate actors can also receive contact damage.
function steam_ball.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return steam_ball
