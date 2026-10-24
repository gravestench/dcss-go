-- An eye reduces sight and accuracy through the existing mutation effect.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")

local definition = {
    id = ids.EYE,
    name = "Eye",
    sacrifice_text = "sacrifice an eye",
    milestone_text = "sacrificed an eye",
    base_piety = 25,
    mutation_id = mutations.MUT_MISSING_EYE,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
