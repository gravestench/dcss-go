-- Resistance weakens protection against extreme heat and cold.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")

local definition = {
    id = ids.RESISTANCE,
    name = "Resistance",
    sacrifice_text = "sacrifice your resistance to extreme temperatures",
    milestone_text = "sacrificed resistance",
    base_piety = 50,
    mutation_id = mutations.MUT_TEMPERATURE_SENSITIVITY,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
