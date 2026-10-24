-- Stealth removes both training and practical stealth, so invested skill contributes to the price.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")
local skills = require("ids.pinned_skills")

local definition = {
    id = ids.STEALTH,
    name = "Stealth",
    sacrifice_text = "sacrifice your ability to go unnoticed",
    milestone_text = "sacrificed stealth",
    base_piety = 15,
    mutation_id = mutations.MUT_NO_STEALTH,
    skill_id = skills.SK_STEALTH,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
