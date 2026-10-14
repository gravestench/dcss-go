local basic = require("policy.generation.basic")
local nearest = require("policy.generation.nearest")

local generated = {}

local exit_unavailable = "Leaving the Dungeon is unavailable in the Go port."
local third_unavailable = "Dungeon:3 is unavailable in the Go port."

local function monster_count(ctx, depth)
    local die_size = depth == 1 and 12 or 10
    local count = 0

    for _ = 1, 3 do
        count = count + ctx:random("population-count", die_size) + 1
    end

    return count
end

local function stair_links(first, second)
    local first_links = {}
    local second_links = {}

    for index, first_pair in ipairs(first.stairs) do
        local second_pair = second.stairs[index]

        first_links[#first_links + 1] = {
            x = first_pair.up.x,
            y = first_pair.up.y,
            to_level_id = 0,
            to_x = 0,
            to_y = 0,
            unavailable = exit_unavailable,
        }
        first_links[#first_links + 1] = {
            x = first_pair.down.x,
            y = first_pair.down.y,
            to_level_id = 2,
            to_x = second_pair.up.x,
            to_y = second_pair.up.y,
            unavailable = "",
        }
        second_links[#second_links + 1] = {
            x = second_pair.up.x,
            y = second_pair.up.y,
            to_level_id = 1,
            to_x = first_pair.down.x,
            to_y = first_pair.down.y,
            unavailable = "",
        }
        second_links[#second_links + 1] = {
            x = second_pair.down.x,
            y = second_pair.down.y,
            to_level_id = 0,
            to_x = 0,
            to_y = 0,
            unavailable = third_unavailable,
        }
    end

    return first_links, second_links
end

function generated.generate(ctx)
    local first = basic.generate(ctx, 1)
    local second = basic.generate(ctx, 2)
    local first_links, second_links = stair_links(first, second)
    local first_budget = monster_count(ctx, 1)
    local second_budget = monster_count(ctx, 2)
    local entry = first.stairs[1].up
    local second_entry = second.stairs[1].up

    local curing = nearest.open_floor(first.rows, entry, nil, 1)
    local heal = nearest.open_floor(second.rows, second_entry, nil, 2)
    local haste = nearest.open_floor(second.rows, second_entry, heal, 2)

    curing.level_id = 1
    heal.level_id = 2
    haste.level_id = 2

    return {
        levels = {
            {
                id = 1,
                rows = first.rows,
                stairs = first_links,
                entry_x = entry.x,
                entry_y = entry.y,
                initial_monsters = first_budget,
            },
            {
                id = 2,
                rows = second.rows,
                stairs = second_links,
                entry_x = second_entry.x,
                entry_y = second_entry.y,
                initial_monsters = second_budget,
            },
        },
        entry = {
            x = entry.x,
            y = entry.y,
        },
        curing = curing,
        heal = heal,
        haste = haste,
    }
end

return generated
