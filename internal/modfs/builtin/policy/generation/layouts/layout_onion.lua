-- Theory of operation: phase a selected primitive into nested corridors,
-- cut independent angular gaps in each partition, and optionally fill the
-- center. Snake bends the sampled domain before source zone cleanup.
local runtime = require("policy.generation.layouts.halls_runtime")
local onion = require("policy.generation.layouts.halls_onion")

local layout = {}

-- Execute the pinned hall algorithm with this invocation's grid and RNG.
function layout.layout_onion(api)
    local env = runtime.new(api)
    local crawl = env.crawl
    local util = env.util
    local dgn = env.dgn
    local you = env.you
    local procedural = env.procedural
    local theme = env.theme
    local zonify = env.zonify
    local _G = env

    local gxm, gym = dgn.max_bounds()

    -- TODO:
    --  * Implement chaotic gaps sizing
    --  * Tune params a bit for Snake

    local wall_break = util.random_range_real(0.4, 0.7)

    -- Make the rings
    local num_rings = crawl.random2avg(7, 2) + 2
    local fphase = onion.skin(env, num_rings, wall_break)

    -- Position on map
    fphase = procedural.translate(procedural.scale(fphase, math.min(gxm, gym) / 2 - 2), gxm / 2, gym / 2)

    if you.in_branch("Snake") then
        fphase = procedural.transform.damped_distortion(fphase)
    end

    -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
    procedural.render_map(_G, fphase, function(v)
        return (v > wall_break and "." or "x")
    end)
    zonify.map_fill_zones(_G, 1, "x")

    theme.level_material(_G)

    return env.result()
end

return layout
