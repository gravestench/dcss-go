-- Durability ends Armour training; losing Dodging first increases its cost.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")
local skills = require("ids.pinned_skills")

local definition = {
    id = ids.DURABILITY,
    name = "Durability",
    sacrifice_text = "sacrifice your Armour skill",
    milestone_text = "sacrificed armour",
    base_piety = 30,
    mutation_id = mutations.MUT_NO_ARMOUR_SKILL,
    skill_id = skills.SK_ARMOUR,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
