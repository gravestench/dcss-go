-- Artifice gives up evocations and device use; existing No Love lowers its marginal value.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")
local skills = require("ids.pinned_skills")

local definition = {
    id = ids.ARTIFICE,
    name = "Artifice",
    sacrifice_text = "sacrifice all use of magical tools",
    milestone_text = "sacrificed evocations",
    base_piety = 55,
    mutation_id = mutations.MUT_NO_ARTIFICE,
    skill_id = skills.SK_EVOCATIONS,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
