-- Theory of operation: overlay two independently shaped, sized, and offset
-- onions. XOR or average interference reshapes their corridors; Snake bends
-- both domains independently before source zone and minimum-area checks.
local runtime = require("policy.generation.layouts.halls_runtime")
local onion = require("policy.generation.layouts.halls_onion")

local layout = {}

-- Execute the pinned hall algorithm with this invocation's grid and RNG.
function layout.layout_onion_interference(api)
    local env = runtime.new(api)
    local crawl = env.crawl
    local util = env.util
    local dgn = env.dgn
    local you = env.you
    local procedural = env.procedural
    local zonify = env.zonify
    local _G = env

    local gxm, gym = dgn.max_bounds()

    local wall_break = util.random_range_real(0.4, 0.6)
    local num_rings1 = crawl.random_range(5, 8)
    local num_rings2 = crawl.random_range(5, 8)

    local fill_center = crawl.coinflip()
    local frings1 = onion.skin(env, num_rings1, wall_break)
    local frings2 = onion.skin(env, num_rings2, wall_break)

    local dist = crawl.random_range(3, 6)
    local dir = {
        x = util.random_range_real(0.5, 1) * dist,
        y = util.random_range_real(0.5, 1) * dist,
    }

    -- Position on map
    frings1 = procedural.translate(
        procedural.scale(frings1, math.min(gxm, gym) * (3 + crawl.random2(2)) / 8),
        gxm / 2,
        gym / 2
    )
    frings2 = procedural.translate(
        procedural.scale(frings2, math.min(gxm, gym) * (3 + crawl.random2(2)) / 8),
        gxm / 2 + dir.x,
        gym / 2 + dir.y
    )

    if you.in_branch("Snake") then
        frings1 = procedural.transform.damped_distortion(frings1)
        frings2 = procedural.transform.damped_distortion(frings2)
    end

    -- Generate the interference pattern by combining the two functions
    local xor = crawl.coinflip()
    -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
    local fphase = function(x, y)
        if xor then
            if frings1(x, y) > wall_break then
                return frings2(x, y) > wall_break and 0 or 1
            else
                return frings2(x, y) > wall_break and 1 or 0
            end
        end
        return (frings1(x, y) + frings2(x, y)) / 2
    end

    -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
    procedural.render_map(_G, fphase, function(v)
        return (v > wall_break and "." or "x")
    end)

    zonify.map_fill_zones(_G, 1, "x")

    return env.result()
end

-- Source minimum_map_area requires strictly more than 10% floor before stairs.
function layout.validate(result)
    return runtime.minimum_area(result, 10, ".{([})]<>")
end

return layout
