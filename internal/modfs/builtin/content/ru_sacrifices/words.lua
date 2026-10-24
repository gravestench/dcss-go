-- Words removes safe reading at low health; the source raises this mutation to its three-rank cap on acceptance.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")

local definition = {
    id = ids.WORDS,
    name = "Words",
    sacrifice_text = "sacrifice your ability to read when badly injured",
    milestone_text = "sacrificed words",
    base_piety = 30,
    mutation_id = mutations.MUT_READ_SAFETY,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
