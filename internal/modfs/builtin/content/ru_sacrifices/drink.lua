-- Drink removes safe potion use at low health; an already potionless character cannot be offered it.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")

local definition = {
    id = ids.DRINK,
    name = "Drink",
    sacrifice_text = "sacrifice your ability to drink when badly injured",
    milestone_text = "sacrificed drink",
    base_piety = 30,
    mutation_id = mutations.MUT_DRINK_SAFETY,
    offer_rule_module = "policy.religion.ru.rules.drink",
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
