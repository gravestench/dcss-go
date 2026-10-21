-- Theory of operation: Spider draws neighbor limits, connection odds, and
-- frontier width before the shared delve pass. Those three choices create
-- either narrow winding galleries or a broad connected mesh. A one-in-four
-- second pass floods newly carved galleries while preserving the dry route.
local grid = require("policy.generation.grid")
local delve = require("policy.generation.layouts.delve")

local layout = {}

-- Weighted source options retain their declared order. The draw belongs
-- to this layout, not a generic branch selector or hidden module state.
local function weighted(builder, options)
    local total = 0

    for _, option in ipairs(options) do
        total = total + option.weight
    end

    local draw = builder:roll(total)

    for _, option in ipairs(options) do
        if draw < option.weight then
            return option.value
        end

        draw = draw - option.weight
    end

    error("Spider delve weight draw exceeded its options")
end

-- The high top values are allowed only when max neighbors is modest;
-- combining both would make nearly the whole level open in the source.
local function parameters(builder)
    local minimum = 2
    local maximum = 3 + builder:roll(4)

    if builder:one_in(5) then
        maximum = 7 + builder:roll(2)
    end

    if builder:one_in(10) then
        minimum = 1
        maximum = 5 + builder:roll(3)
    elseif builder:one_in(20) then
        minimum = 3
        maximum = 4
    end

    local connection = weighted(builder, {
        {
            value = 0,
            weight = 2,
        },
        {
            value = 5,
            weight = 1,
        },
        {
            value = 20,
            weight = 1,
        },
        {
            value = 50,
            weight = 1,
        },
        {
            value = 100,
            weight = 1,
        },
    })
    local top = weighted(builder, {
        {
            value = 1,
            weight = 1,
        },
        {
            value = 20,
            weight = 1,
        },
        {
            value = 125,
            weight = 1,
        },
    })

    if maximum < 7 then
        top = weighted(builder, {
            {
                value = top,
                weight = 3,
            },
            {
                value = 500,
                weight = 1,
            },
            {
                value = 999999,
                weight = 1,
            },
        })
    end

    return minimum, maximum, connection, top
end

-- A water pass protects existing floor as @, carves through remaining x,
-- then converts only the new floor to deep water. The dry route survives.
local function maybe_water(builder, minimum, maximum, top)
    if not builder:one_in(4) then
        return false
    end

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            if builder:cell(x, y) == "." then
                builder:set(x, y, "@")
            end
        end
    end

    delve.carve(builder, minimum, maximum, 100, 100, top)

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            local glyph = builder:cell(x, y)

            if glyph == "." then
                builder:set(x, y, "w")
            elseif glyph == "@" then
                builder:set(x, y, ".")
            end
        end
    end

    return true
end

-- Source Spider uses the full builder extent and reserves only its rim.
function layout.generate(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local minimum, maximum, connection, top = parameters(builder)

    delve.prepare(builder)
    delve.carve(builder, minimum, maximum, connection, -1, top)

    local water = maybe_water(builder, minimum, maximum, top)

    delve.finish(builder)

    return {
        builder = builder,
        water = water,
        minimum = minimum,
        maximum = maximum,
        connection = connection,
        top = top,
    }
end

return layout
