-- A sparse mod adds one Dungeon row without copying its source table.
-- The monster profile and placement weight live in separate files because
-- either can be overridden independently by another layer.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local monsters = require("ids.monsters")

local definition = {
    id = "test.moss.dungeon",
    branch_id = branches.BRANCH_DUNGEON,
    rows = {
        {
            monster_id = monsters.MONS_TEST_MOSS,
            min_depth = 1,
            max_depth = 3,
            rarity = 1000,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
