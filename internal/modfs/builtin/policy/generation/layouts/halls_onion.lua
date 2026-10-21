-- Theory of operation: one primitive distance field is split into phase rings.
-- Independent angular phases punch the partition walls and a center roll may
-- replace the innermost phase with a full room. Keep unused source draws too.
local onion = {}

-- Construct each onion from the invocation's source-style helper bindings.
function onion.skin(env, num_rings, wall_break)
    local crawl = env.crawl
    local util = env.util
    local procedural = env.procedural
    local primitive = env.primitive

    local onion_weights = {
        -- TODO: More shapes are possible; triangle, oval, rectangle, elongated circle,
        -- actually a generic polygon covers the triangle case, maybe irregular polygons,
        -- stars,
        {
            weight = 10,
            -- Construct the selected source circular distance field before sampling rings.
            func = function()
                return primitive.distance
            end,
        },
        {
            weight = 10,
            -- Construct the selected source box distance field before sampling rings.
            func = function()
                return primitive.box
            end,
        },
        {
            weight = 10,
            -- Construct the selected source diamond distance field before sampling rings.
            func = function()
                return primitive.diamond()
            end,
        },
        {
            weight = 10,
            -- Construct the selected source octagon distance field before sampling rings.
            func = function()
                return primitive.octagon(0.25)
            end,
        },
        {
            weight = 10,
            -- Construct the selected source hexagon distance field before sampling rings.
            func = function()
                return primitive.hexagon(0.25)
            end,
        },
    }

    local chosen = util.random_weighted_from("weight", onion_weights)
    local fcircle = chosen.func()

    -- Make holes in each partitioning wall
    local rings = {}
    -- This unused source draw still advances the saved layout stream.
    local hole_size = util.random_range_real(0.1, 0.3)

    -- TODO: There are some other functions that could be used to carve holes; e.g. spirals, worley ...
    -- Draw the source's unused hole count before selecting angular repetition and phase.
    local phasering = function(size)
        local num = crawl.random_range(5 * size, 20 * size) + 1
        return procedural.phase(primitive.radial, crawl.random_range(2, 10), crawl.random_real())
    end

    for n = 1, num_rings - 1, 1 do
        rings[n] = phasering(n / num_rings)
    end

    -- Do we create a central room?
    local fill_center = crawl.coinflip()

    -- Split primitive distance into ring phases, replacing wall bands by their gap fields.
    local fphase = function(x, y)
        local r = fcircle(x, y)
        if r >= 1 then
            return -1
        end
        local rr = r * num_rings
        local level = math.floor(rr)
        r = rr - level
        if fill_center and level == 0 then
            return 1
        end

        -- Fill connecting walls?
        if level > 0 and r <= wall_break then
            local hole = rings[level]
            if hole ~= nil then
                return hole(x, y)
            end
        end

        return r
    end

    return fphase
end

return onion
