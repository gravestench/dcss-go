-- Theory of operation: source tilepick assigns each irregular cell one
-- room, corridor, or wall tile. Its neighbor weights make some rooms grow
-- as groups while corridor cells remain eligible anywhere. The renderer
-- consumes only these tiles and does not decide the source grouping.
local groups = require("policy.generation.layouts.cellular_groups")

local tiles = {}

local tile_choices = {
    "room",
    "room",
    "room",
    "corridor",
    "corridor",
    "corridor",
    "corridor",
    "wall",
}

-- A room may join exactly one adjacent room group without touching a
-- different group diagonally. Random-room branches bypass that restriction.
local function room_weight(tiling, index, choices)
    if choices.random_rooms then
        return 10
    end

    local direct, track = tiling:adjacent(index, "room", false)
    local nearby = tiling:adjacent(index, "room", true)

    if direct == 1 and nearby == 1 then
        for group in pairs(track) do
            return math.ceil(20 / tiling:size(group))
        end
    elseif nearby == 0 then
        return 10
    end

    return 0
end

-- A wall can grow from one existing group or seed itself, preferring the
-- padded boundary where it can connect to the outer rock field.
local function wall_weight(tiling, index)
    local direct = tiling:adjacent(index, "wall", false)
    local nearby = tiling:adjacent(index, "wall", true)

    if direct == 1 and nearby == 1 then
        return 20
    elseif nearby == 0 then
        return tiling:edge_count(index) > 0 and 10 or 5
    end

    return 0
end

-- Corridors are always eligible. This lets the one-tile-per-cell loop
-- complete when room and wall growth rules reject the remaining gaps.
local function tile_weight(tiling, index, tile, choices)
    if tile == "room" then
        return room_weight(tiling, index, choices)
    elseif tile == "wall" then
        return wall_weight(tiling, index)
    end

    return 10
end

-- Corridors accept every remaining cell when a requested tile has no
-- legal placement under its own adjacency rule.
local function corridor_weight()
    return 10
end

-- Use the source 3:4:1 room:corridor:wall tile draw. If its requested
-- tile has no eligible cells, the always-eligible corridor fills the gap.
function tiles.assign(builder, cells, edges, bounds, choices)
    local tiling = groups.new(cells, edges, bounds)

    for _ = 1, #cells do
        local tile = tile_choices[builder:roll(#tile_choices) + 1]

        -- Bind this floor's branch choices to the generic group selector.
        local index = tiling:choose(builder, tile, function(state, candidate)
            return tile_weight(state, candidate, tile, choices)
        end)

        if not index then
            tile = "corridor"
            index = tiling:choose(builder, tile, corridor_weight)
        end

        tiling:place(index, tile)
    end

    return tiling
end

return tiles
