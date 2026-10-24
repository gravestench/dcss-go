-- Essence trades magic strength or willpower for piety; variant identity changes the source price.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local pools = require("constants.ru_variant_pools")

local definition = {
    id = ids.ESSENCE,
    name = "Essence",
    sacrifice_text = "corrupt yourself such that",
    milestone_text = "sacrificed essence",
    base_piety = 0,
    variant_pool = pools.ESSENCE,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
