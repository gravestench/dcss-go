-- Some monster rays seed a cloud in every traversed cell before making a
-- larger field at their endpoint. Keep cloud placement in the world-cloud
-- owner so each cell has ordinary attribution, replacement, and save state.
local placement = require("policy.clouds.placement")
local streams = require("constants.rng_streams")

local trail = {}

-- The source rolls a fresh duration for every travelled cell. Use the
-- monster-spell stream so continuing a saved game repeats those draws.
function trail.place(ctx, caster, cloud_id, endpoint, base_turns,
    random_turns)
    for _, cell in ipairs(endpoint.path or {}) do
        local turns = base_turns +
            ctx:random(streams.MONSTER_SPELL, random_turns)

        placement.place(ctx, cloud_id, caster,
            endpoint.level_id, cell.x, cell.y, turns * 10)
    end
end

return trail
