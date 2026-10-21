-- Theory of operation: Chaotic City opens a broad square of street inside
-- rock, populates it with source-sized separated buildings, then sometimes
-- clears a central octagonal market. The ordinary layout owner adds stairs
-- after this hook returns its dense terrain grid.
local grid = require("policy.generation.grid")
local boxes = require("policy.generation.layouts.chaotic_city_boxes")

local layout = {}

-- The C++ builder begins by replacing rock inside a ten-cell inset. This
-- leaves an unbroken outer border where later vaults can still attach.
local function open_streets(builder)
    for y = 10, builder.height - 10 do
        for x = 10, builder.width - 10 do
            builder:set(x, y, ".")
        end
    end
end

-- The source market usually has clipped corners and rarely uses water or
-- lava. Floor markets erase building walls; liquid markets flood only
-- those walls, leaving existing street and building floors untouched.
local function market_material(builder)
    if not builder:one_in(10) then
        return "."
    end

    return builder:one_in(2) and "w" or "l"
end

-- Source _octa_room uses a running oblique value, drawing column strips
-- from left to right. Retain that shape rather than inserting a square.
local function paint_market(builder, oblique, glyph)
    local left = 25
    local top = 25
    local right = 55
    local bottom = 45
    local clip = oblique

    for x = left, right - 1 do
        for y = top + clip, bottom - clip - 1 do
            local current = builder:cell(x, y)

            if current == "#" or current == "c" or current == "v" then
                builder:set(x, y, glyph)
            elseif current == "+" then
                builder:set(x, y, ".")
            end
        end

        if x > right - oblique then
            clip = clip + 2
        end

        if clip > 0 then
            clip = clip - 1
        end
    end
end

-- A one-in-four market is independent of the building count. With no
-- clipping the source still passes zero through the same octagon painter.
local function maybe_market(builder)
    if not builder:one_in(4) then
        return false
    end

    local oblique = 0

    if not builder:one_in(4) then
        oblique = 5 + builder:roll(20)
    end

    paint_market(builder, oblique, market_material(builder))

    return true
end

-- The DES hook owns only this layout's terrain. The shared catalog owns
-- branch selection, connected stairs, vault effects, and save encoding.
local function layout_chaotic_city(api)
    local builder = grid.new(api.ctx, api.width, api.height)

    open_streets(builder)

    local placed = boxes.populate(builder, api.branch)
    local market = maybe_market(builder)

    if builder.bad_random then
        error("Chaotic City random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        boxes = placed,
        market = market,
    }
end

layout.layout_chaotic_city = layout_chaotic_city

return layout
