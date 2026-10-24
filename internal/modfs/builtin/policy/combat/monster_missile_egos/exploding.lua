-- Source throw.cc gives an exploding missile a radius-one fragment bolt
-- with 2d5 damage. Blast propagation and fragment armour remain with the
-- shared Lua area owners, so walls and all nearby actors use one rule.
local explosion = require("policy.combat.explosion")
local impact = require("policy.combat.monster_area.impact")
local flavours = require("constants.beam_flavours")
local streams = require("constants.rng_streams")

local exploding = {}

local profile = {
    flavour = flavours.BEAM_FRAG,
    rng_stream = streams.MELEE,
}

-- Each occupied blast cell rolls its own dice and armour. The shared grid
-- walker includes the impact cell and stops fragments at solid walls.
function exploding.impact(ctx, attacker, level_id, x, y)
    ctx:emit("combat", "The missile explodes into fragments!")

    for _, cell in ipairs(explosion.cells(ctx, level_id,
        x, y, 1, true)) do
        local victim = ctx:actor_at(level_id, cell.x, cell.y)
        local health = victim and ctx:get(victim, "core.health")

        if health and health.current > 0 then
            local raw = 2 + ctx:random(streams.MELEE, 5) +
                ctx:random(streams.MELEE, 5)

            impact.hit(ctx, attacker, victim, raw, profile)
        end
    end
end

return exploding
