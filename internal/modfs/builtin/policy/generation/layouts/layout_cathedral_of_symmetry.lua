-- Theory of operation: extrude a cylinder through 3D Worley space to repeat
-- related vertical patterns. Source branch parameters control symmetry and
-- optional polar wrapping; Zot bottom always receives the polar form.
local runtime = require("policy.generation.layouts.halls_runtime")

local layout = {}

-- Execute the pinned hall algorithm with this invocation's grid and RNG.
function layout.layout_cathedral_of_symmetry(api)
    local env = runtime.new(api)
    local crawl = env.crawl
    local util = env.util
    local dgn = env.dgn
    local you = env.you
    local procedural = env.procedural
    local theme = env.theme
    local zonify = env.zonify
    local unpack = unpack
    local _G = env

    local gxm, gym = dgn.max_bounds()

    -- zscale controls the symmetry within each repetition because with 0
    -- the coord bounces back and forth along a line instead of tracing
    -- a circle. Increasing towards 1 results in less and less symmetry until
    -- we get a standard worley pattern at 1.
    local zscale = 0

    -- zoff gradually increases the z-axis offset as we move along x.
    -- A non-zero value results in each repetition looking slightly different.
    local zoff = 0

    -- How many times to loop the pattern. Use multiples of 0.5 to
    -- take advantage of the symmetrical nature of the algorithm
    local reps = (crawl.random2(8) + 1) / 2

    -- Offsets the whole pattern by a given multiple of repetitions.
    -- This means the large symmetrical parts can be in the middle or on
    -- the edge. Using multiples of 0.25 as these create a distinct geometry.
    local xoff = crawl.random2(4) / 4

    -- Note: varying the scales is very tricky. At higher reps we can't get
    -- away with so much variance.
    -- Vertical axis scale
    local yscale = 1
    -- Scale of the underlying worley
    local wscale = 0.2

    local border = crawl.random_range(3, 6)
    local margin = crawl.random_range(0, 5)

    local polarise = false

    if you.in_branch("tar") then
        -- Tar works best with a lot of dissonance but occasionally
        -- repeating elements
        zscale = util.random_range_real(0.2, 0.6)
        zoff = util.random_range_real(0.1, 0.3)
        yscale = util.random_range_real(0.4, 1) / reps + reps / 10
        wscale = util.random_range_real(0.06, 0.1)
        polarise = crawl.one_chance_in(4)
    else
        -- Zot:5
        if you.at_branch_bottom() then
            reps = crawl.random2(4) + 0.5
            xoff = 0
            border = 6
            margin = 8
        end

        -- In Zot we want a strong set of symmetry and repetition
        zscale = util.random_range_real(0, 0.05)
        zoff = util.random_range_real(0, 0.25)
        yscale = util.random_range_real(0.1, 0.4) / reps + reps / 10
        wscale = util.random_range_real(0.05, 0.08)
        polarise = crawl.coinflip()
    end

    -- If this is being placed to benefit a central vault, do the polar layout.
    local params = dgn.map_parameters()
    if params ~= nil then
        local mode = unpack(params)
        if mode == "central" then
            polarise = true
        end
    end

    -- Zot:5 always gets a polar layout.
    if you.in_branch("zot") and you.at_branch_bottom() then
        polarise = true
    end

    local scale = 80 / reps
    local breakpoint = 0.3
    local fbase = procedural.worley_diff({ scale = wscale })
    fbase = procedural.transform.wrapped_cylinder(fbase, scale, scale, zscale, zoff)
    fbase = procedural.scale(fbase, 1, yscale)
    fbase = procedural.translate(fbase, scale * xoff / 2, 0)
    -- Perform polar transform.
    -- TODO: On certain settings this starts looking like a giant spiderweb. Should enable this
    -- layout in Spider with tuned settings and polarise = true
    if polarise then
        fbase = procedural.translate(procedural.transform.polar(fbase, gym / 2, gxm, gym), gxm / 2, gym / 2)
    end
    fbase = procedural.add(
        fbase,
        procedural.mul(
            breakpoint,
            procedural.border({
                padding = border,
                margin = margin,
            })
        )
    )

    -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
    procedural.render_map(_G, fbase, function(v)
        return (v < breakpoint and "." or "x")
    end)
    zonify.map_fill_zones(_G, 1, "x")
    theme.level_material(_G)

    return env.result()
end

return layout
