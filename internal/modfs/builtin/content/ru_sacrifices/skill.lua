-- Skill slows all future training; repeated levels carry an increasing source price.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")

local definition = {
    id = ids.SKILL,
    name = "Skill",
    sacrifice_text = "sacrifice your skill",
    milestone_text = "sacrificed skill",
    base_piety = 30,
    mutation_id = mutations.MUT_UNSKILLED,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
