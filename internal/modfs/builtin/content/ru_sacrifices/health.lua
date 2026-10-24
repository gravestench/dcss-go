-- Health can reduce HP, armour, or evasion; the selected mutation is saved with the offer.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local pools = require("constants.ru_variant_pools")

local definition = {
    id = ids.HEALTH,
    name = "Health",
    sacrifice_text = "corrupt yourself such that",
    milestone_text = "sacrificed health",
    base_piety = 25,
    variant_pool = pools.HEALTH,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
