-- Love forbids allies and summoning; prior losses of summoning or artifice reduce its value.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")
local skills = require("ids.pinned_skills")

local definition = {
    id = ids.LOVE,
    name = "Love",
    sacrifice_text = "sacrifice your ability to be loved",
    milestone_text = "sacrificed love",
    base_piety = 40,
    mutation_id = mutations.MUT_NO_LOVE,
    skill_id = skills.SK_SUMMONINGS,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
