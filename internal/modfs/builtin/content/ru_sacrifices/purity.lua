-- Purity offers one lasting defect from six harmful mutation choices; its value depends on the exact defect rolled.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local pools = require("constants.ru_variant_pools")

local definition = {
    id = ids.PURITY,
    name = "Purity",
    sacrifice_text = "corrupt yourself such that",
    milestone_text = "sacrificed purity",
    base_piety = 0,
    variant_pool = pools.PURITY,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
