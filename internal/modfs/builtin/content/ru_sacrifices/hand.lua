-- A hand costs a shield, some weapons, and one ring slot in addition to Shields training.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")
local skills = require("ids.pinned_skills")

local definition = {
    id = ids.HAND,
    name = "Hand",
    sacrifice_text = "sacrifice one of your ",
    milestone_text = "sacrificed a hand",
    base_piety = 65,
    mutation_id = mutations.MUT_MISSING_HAND,
    skill_id = skills.SK_SHIELDS,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
