-- Arcana removes one school from each of three severity groups; all three choices must be saved together.
local categories = require("constants.catalog")
local ids = require("ids.ru_sacrifices")
local pools = require("constants.ru_variant_pools")

local definition = {
    id = ids.ARCANA,
    name = "Arcana",
    sacrifice_text = "sacrifice all use of",
    milestone_text = "sacrificed arcana",
    base_piety = 25,
    variant_pool = pools.ARCANA,
}

register.definition(categories.RU_SACRIFICES, definition)

return definition
