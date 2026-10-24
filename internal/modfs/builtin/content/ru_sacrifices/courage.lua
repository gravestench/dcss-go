-- Courage makes nearby enemies more frightening; prior lost experience increases the price.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")

local definition = {
    id = ids.COURAGE,
    name = "Courage",
    sacrifice_text = "sacrifice your courage",
    milestone_text = "sacrificed courage",
    base_piety = 25,
    mutation_id = mutations.MUT_COWARDICE,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
