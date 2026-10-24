-- Nimbleness ends Dodging training; losing Armour first makes this sacrifice harder.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")
local skills = require("ids.pinned_skills")

local definition = {
    id = ids.NIMBLENESS,
    name = "Nimbleness",
    sacrifice_text = "sacrifice your Dodging skill",
    milestone_text = "sacrificed dodging",
    base_piety = 30,
    mutation_id = mutations.MUT_NO_DODGING,
    skill_id = skills.SK_DODGING,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
