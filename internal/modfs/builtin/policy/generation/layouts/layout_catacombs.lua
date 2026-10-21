-- Theory of operation: invert an onion so partition bands become chambers,
-- then join them with distorted radial rays or a signed simplex contour.
-- Crypt can flood simplex connectors; the source validator rejects tiny maps.
local runtime = require("policy.generation.layouts.halls_runtime")
local onion = require("policy.generation.layouts.halls_onion")

local layout = {}

-- Execute the pinned hall algorithm with this invocation's grid and RNG.
function layout.layout_catacombs(api)
    local env = runtime.new(api)
    local crawl = env.crawl
    local util = env.util
    local dgn = env.dgn
    local you = env.you
    local procedural = env.procedural
    local primitive = env.primitive
    local complex = env.complex
    local theme = env.theme
    local zonify = env.zonify
    local _G = env

    local gxm, gym = dgn.builder_bounds()

    -- Make the rings
    local num_rings = crawl.random2avg(4, 2) + 4
    local wall_break = util.random_range_real(0.4, 0.7)
    local fphase = onion.skin(env, num_rings, wall_break)

    -- Position on map
    fphase = procedural.translate(
        procedural.scale(fphase, math.min(gxm, gym) / (crawl.random2(3) / 2 + 1)),
        gxm / 2,
        gym / 2
    )

    local use_water = you.in_branch("crypt") and crawl.one_chance_in(4)

    -- Pick a connector function to link up the rooms
    local fconnect
    if crawl.coinflip() then
        fconnect = complex.rays(
            crawl.random_range(5, 10),
            crawl.random_real(),
            util.random_range_real(30, 35),
            util.random_range_real(0.1, 0.2)
        )
        -- Distort more the further out the rays go
        local fdsx = procedural.simplex3d({
            scale = util.random_range_real(0.5, 1),
            unit = false,
        })
        local fdsy = procedural.simplex3d({
            scale = util.random_range_real(0.5, 1),
            unit = false,
        })
        local fedge = procedural.min(1, procedural.div(primitive.distance, math.min(gxm, gym) / 2))
        local fdx = procedural.mul(fdsx, fedge)
        local fdy = procedural.mul(fdsy, fedge)
        fconnect = procedural.distort({
            source = fconnect,
            scale = crawl.random_range(10, 20),
            offsetx = fdx,
            offsety = fdy,
        })
        fconnect = procedural.translate(fconnect, gxm / 2, gym / 2)
        use_water = false
    else
        fconnect = procedural.abs(procedural.simplex3d({
            scale = util.random_range_real(0.6, 0.8),
            unit = false,
        }))
    end

    local connect_glyph = "."
    local water_glyph = "W"

    -- Do the render
    -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
    procedural.render_map(_G, fphase, function(v, x, y)
        local vconn = fconnect(x, y)
        if vconn < 0.1 then
            if use_water and (v == -1 or vconn < 0.06) then
                return water_glyph
            elseif v > -1 then
                return connect_glyph
            end
        end
        return (v < wall_break and v > -1 and "." or "x")
    end)

    zonify.map_fill_zones(_G, 1, "x")
    theme.level_material(_G)

    return env.result()
end

-- Source minimum_map_area requires strictly more than 15% floor before stairs.
function layout.validate(result)
    return runtime.minimum_area(result, 15, ".W")
end

return layout
