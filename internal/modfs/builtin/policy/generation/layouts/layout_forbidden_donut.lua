-- Theory of operation: this once-per-run Depths layout carves four broad
-- strips into rock, leaving a central hole. Some draws cross the hole with
-- corridors and insert a small octagon of floor, water, or lava. The source
-- then roughens either the floor or its rock boundary and applies a theme.
-- The shared layout postpass adds connected ordinary stairs afterward.
local grid = require("policy.generation.grid")
local material = require("policy.generation.layouts.material")
local spotty = require("policy.generation.layouts.spotty")

local layout = {}

-- Keep source rectangles inclusive, including their unusual lower and
-- right strip coordinates. Changing them makes a different ring shape.
local function fill(builder, x1, y1, x2, y2, glyph)
    for y = y1, y2 do
        for x = x1, x2 do
            builder:set(x, y, glyph)
        end
    end
end

-- Four connected strips make the wide ring while preserving rock in its
-- center. The source width is ten minus a bounded seven-way draw.
local function carve_ring(builder)
    local width = 10 - builder:roll(7)

    fill(builder, 10, 10, grid.width - 10, 10 + width, ".")
    fill(builder, 10, 60 - width, grid.width - 10,
        grid.height - 10, ".")
    fill(builder, 10, 10, 10 + width, grid.height - 10, ".")
    fill(builder, 60 - width, 10, grid.width - 10,
        grid.height - 10, ".")
end

-- The source octa_room changes only untouched rock. Its oblique offset
-- clips the top and bottom corners; even a large offset may leave no cells.
local function carve_octagon(builder, oblique, glyph)
    local left = 25
    local top = 25
    local right = grid.width - 25
    local bottom = grid.height - 25

    for y = top, bottom do
        for x = left, right do
            local cut = math.max(oblique + left - x, 0) +
                math.max(oblique + x - right, 0)

            if y >= top + cut and y <= bottom - cut and
                builder:cell(x, y) == "#" then
                builder:set(x, y, glyph)
            end
        end
    end
end

-- The central octagon's source weights favor floor over water and lava.
-- A separate coin flip determines whether to clip its corners at all.
local function octagon_material(builder)
    local draw = builder:roll(16)

    if draw < 10 then
        return "."
    elseif draw < 15 then
        return "w"
    end

    return "l"
end

-- A cross gives the ring a shorter route between opposite sides. Its
-- optional octagon also reduces later spotty-map probability to one fifth.
local function carve_middle(builder, spotty_chosen)
    if not builder:one_in(2) then
        return spotty_chosen
    end

    local width = 1 + builder:roll(5)
    local center_x = grid.width / 2
    local center_y = grid.height / 2

    fill(builder, 10, center_y - width,
        grid.width - 10, center_y + width, ".")
    fill(builder, center_x - width, 10,
        center_x + width, grid.height - 10, ".")

    if builder:one_in(2) then
        local oblique = 0

        if builder:one_in(2) then
            oblique = 5 + builder:roll(20)
        end

        carve_octagon(builder, oblique, octagon_material(builder))
        spotty_chosen = builder:one_in(5)
    end

    return spotty_chosen
end

-- Source calls spotty_map with its own default iteration draw. A boxy
-- smear uses cardinal neighbors; a rounded smear also uses diagonals.
local function roughen(builder, spotty_chosen, smears)
    local spotty_boxy = builder:one_in(2)
    local smear_boxy = builder:one_in(2)

    if spotty_chosen then
        local limit = spotty_boxy and 750 or 1500

        spotty.carve(builder, spotty_boxy, builder:roll(limit))
    end

    if spotty_chosen or builder:one_in(4) then
        spotty.smear(builder, smears, smear_boxy)
    end
end

-- All choices use the layout stream so file load order cannot alter a
-- seeded level. The catalog owns postpass stairs and final row capture.
function layout.generate(api)
    local builder = grid.new(api.ctx)

    carve_ring(builder)

    local spotty_chosen = builder:one_in(2)
    local smears = builder:roll(300)

    spotty_chosen = carve_middle(builder, spotty_chosen)
    roughen(builder, spotty_chosen, smears)

    if spotty_chosen then
        material.caves(builder, api)
    else
        material.level(builder, api)
    end

    return { builder = builder }
end

return layout
