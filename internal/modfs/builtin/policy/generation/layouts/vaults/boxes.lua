-- Theory of operation: these Vaults motifs start from broad rectangular
-- regions. The surrounding room pass attaches authored rooms to their walls
-- and open centers, so the source paint remains simple and legible here.
local grid = require("policy.generation.grid")
local geometry = require("policy.generation.layouts.vaults.geometry")

local boxes = {}

-- Mumra's ring uses a five-cell passage around a solid inner block. Its
-- outer padding leaves rock where the room pass can attach more chambers.
function boxes.ring(builder, wall)
    local padding = 20
    local corridor = 5

    geometry.rectangle(builder, padding, padding,
        grid.width - padding - 1, grid.height - padding - 1, ".")
    geometry.rectangle(builder, padding + corridor, padding + corridor,
        grid.width - padding - corridor - 1,
        grid.height - padding - corridor - 1, wall)
end

-- Omnibox chooses two corners at least six cells apart. Small draws become
-- a compact central room; large draws can resemble chaotic city or a ring.
function boxes.omnibox(builder)
    local minimum = 6
    local left = geometry.range(builder, 1, grid.width - minimum - 3)
    local top = geometry.range(builder, 1, grid.height - minimum - 3)
    local right = geometry.range(builder, left + minimum - 1,
        grid.width - 2)
    local bottom = geometry.range(builder, top + minimum - 1,
        grid.height - 2)

    geometry.rectangle(builder, left, top, right, bottom, ".")
end

-- The big room keeps ten to twenty cells of surrounding wall on each side.
-- Room placement can cut through that wall without shrinking the main hall.
function boxes.big_room(builder)
    local horizontal = geometry.range(builder, 10, 20)
    local vertical = geometry.range(builder, 10, 20)

    geometry.rectangle(builder, horizontal, vertical,
        grid.width - horizontal - 1, grid.height - vertical - 1, ".")
end

-- Chaotic city has no initial walls inside the boundary. Authored and code
-- rooms create the streets and buildings during the later room pass.
function boxes.chaotic_city(builder)
    geometry.rectangle(builder, 1, 1,
        grid.width - 2, grid.height - 2, ".")
end

return boxes
