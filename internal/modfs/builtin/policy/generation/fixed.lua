local branches = require("ids.branches")

local fixed = {}

local first_rows = {
    "#################",
    "#.......#.......#",
    "#.#.....#.......#",
    "#......>#.......#",
    "#...............#",
    "#.......#.......#",
    "#.......#.......#",
    "#.......#.......#",
    "#################",
}

local second_rows = {
    "#################",
    "#<......#.......#",
    "#.......#.......#",
    "#.......#.......#",
    "#...............#",
    "#.......#.......#",
    "#.......#.......#",
    "#.......#.......#",
    "#################",
}

function fixed.generate(populated)
    local budget = populated and 2 or 0

    return {
        levels = {
            {
                id = 1,
                branch_id = branches.BRANCH_DUNGEON,
                rows = first_rows,
                entry_x = 1,
                entry_y = 1,
                initial_monsters = budget,
                stairs = {
                    {
                        x = 7,
                        y = 3,
                        to_level_id = 2,
                        to_x = 1,
                        to_y = 1,
                        unavailable = "",
                    },
                },
            },
            {
                id = 2,
                branch_id = branches.BRANCH_DUNGEON,
                rows = second_rows,
                entry_x = 1,
                entry_y = 1,
                initial_monsters = budget,
                stairs = {
                    {
                        x = 1,
                        y = 1,
                        to_level_id = 1,
                        to_x = 7,
                        to_y = 3,
                        unavailable = "",
                    },
                },
            },
        },
        entry = { x = 1, y = 1 },
        curing = { level_id = 1, x = 4, y = 2 },
        heal = { level_id = 2, x = 2, y = 1 },
        haste = { level_id = 2, x = 3, y = 1 },
    }
end

return fixed
