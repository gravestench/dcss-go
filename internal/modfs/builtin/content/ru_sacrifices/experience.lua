-- Experience permanently lowers effective level and is unavailable before the source level threshold.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")

local definition = {
    id = ids.EXPERIENCE,
    name = "Experience",
    sacrifice_text = "sacrifice your experiences",
    milestone_text = "sacrificed experience",
    base_piety = 35,
    mutation_id = mutations.MUT_INEXPERIENCED,
    offer_rule_module = "policy.religion.ru.rules.experience",
    accept_module = "policy.religion.ru.consequences.experience",
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
