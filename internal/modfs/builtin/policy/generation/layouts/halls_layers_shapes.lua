-- Theory of operation: hall layers choose one source factory from each
-- of three geometric scales. These tables allocate closures without drawing;
-- their selected constructors draw only after all three weighted selections.
local shapes = {}

-- Keep the four full-map source motifs and their unequal selection weights.
function shapes.primary(env, width)
    local crawl = env.crawl
    local util = env.util
    local procedural = env.procedural
    local primitive = env.primitive
    local complex = env.complex

    return {
        {
            weight = 10,
            func = primitive.cross,
        },
        {
            weight = 3,
            func = primitive.ex,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return procedural.mul(
                    crawl.random_range(4, 8),
                    procedural.sub(primitive.distance, primitive.box)
                )
            end,
        },
        -- Rays
        {
            weight = 5,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return procedural.mul(
                    width * 8,
                    procedural.phase(primitive.radial, crawl.random_range(4, 8), crawl.random_real())
                )
            end,
        },
    }
end

-- Retain all seven source contours that circle the level at medium scale.
function shapes.outer(env, width, gym)
    local crawl = env.crawl
    local util = env.util
    local procedural = env.procedural
    local primitive = env.primitive
    local complex = env.complex

    return {
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return primitive.ring(gym / 3)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return primitive.ringify(primitive.box, gym / 3)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return primitive.ringify(primitive.diamond(), 2 / 5 * gym)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return primitive.ringify(primitive.octagon(crawl.random_range(5, 20)), gym / 3)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return primitive.ringify(primitive.hexagon(crawl.random_range(5, 15)), gym / 3)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return procedural.mul(
                    1.8,
                    primitive.ringify(procedural.scale(primitive.triangle(), 1, 2), gym / 6)
                )
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return procedural.mul(
                    width,
                    procedural.map(
                        procedural.scale(
                            complex.cog(
                                crawl.random_range(10, 30), -- Teeth
                                util.random_range_real(0.7, 0.9), -- Inner distance
                                util.random_range_real(0.3, 0.6), -- Gap between teeth
                                util.random_range_real(0, 1)
                                -- Offset (TODO: Fix how the procedural
                                -- works so we can align at 0 or 0.5 for
                                -- symmettry)
                            ),
                            gym * 4 / 9
                        ),
                        {
                            {
                                0,
                                0.9,
                                2,
                                2,
                            },
                            {
                                0.9,
                                1,
                                0.9,
                                1,
                            },
                        }
                    )
                )
            end,
        },
    }
end

-- Choose central scale and corridor thickness using the source conditional rolls.
local function scale_or_ring(env, prim, size)
    local crawl = env.crawl
    local procedural = env.procedural
    local primitive = env.primitive

    if crawl.one_chance_in(3) then
        -- Larger central shape
        return procedural.scale(prim, 2)
    elseif crawl.coinflip() then
        -- Small ring
        return primitive.ringify(prim, size / 2)
    elseif crawl.one_chance_in(8) then
        -- Very rarely don't actually scale it - it's quite interesting when
        -- e.g. circle and diamond overlap at the same size.
        return primitive.ringify(prim, size)
    else
        -- Small ring w/narrower corridors
        return procedural.scale(primitive.ringify(prim, size), 0.5)
    end
end

-- Retain every small source ring, cross, cog, and spiral as an independent choice.
function shapes.inner(env, width, gym)
    local crawl = env.crawl
    local util = env.util
    local procedural = env.procedural
    local primitive = env.primitive
    local complex = env.complex

    return {
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return scale_or_ring(env, primitive.distance, gym / 3)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return scale_or_ring(env, primitive.box, gym / 3)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return scale_or_ring(env, primitive.octagon(crawl.random_range(4, 8)), gym / 3)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return scale_or_ring(env, primitive.hexagon(crawl.random_range(4, 8)), gym / 3)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return scale_or_ring(env, procedural.scale(primitive.triangle(), 1, 2), gym / 6)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return scale_or_ring(env, primitive.diamond(), 2 / 5 * gym)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return procedural.scale(primitive.ex(), 0.5)
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return primitive.ringify(primitive.ex(), crawl.random_range(gym / 6, gym / 4))
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return primitive.ringify(primitive.cross(), crawl.random_range(gym / 6, gym / 4))
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return procedural.mul(
                    crawl.random_range(2, 4),
                    primitive.ringify(procedural.sub(primitive.distance, primitive.box), 6)
                )
            end,
        },
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                return procedural.mul(
                    width,
                    procedural.scale(
                        complex.cog(
                            crawl.random_range(3, 8) * 2, -- Teeth
                            util.random_range_real(0.1, 0.9), -- Inner distance
                            util.random_range_real(0.4, 0.6), -- Gap between teeth
                            util.random_range_real(0, 1)
                            -- Offset (TODO: Fix how the procedural works so we
                            -- can align at 0 or 0.5 for symmettry)
                        ),
                        gym / 4
                    )
                )
            end,
        },
        -- Spiral -- this didn't work too well as a primary function, but it looks awesome
        -- when overlaid with a second-level gear. It'd be nice to make it able to overlay
        -- with both gears on those extremely rare occasions.
        {
            weight = 10,
            -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
            func = function()
                local rot = crawl.random_range(5, 20)
                -- Evaluate the selected source field or glyph rule in the shared coordinate domain.
                return function(x, y)
                    local r = primitive.radial(x, y)
                    local d = primitive.distance(x, y)
                    if d > gym / 2 then
                        return width
                    end
                    return (r + d / rot) % 1 * width * rot * 0.4
                end
            end,
        },
    }
end

return shapes
