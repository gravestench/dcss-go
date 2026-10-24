-- Pinned source names are available while the content tree loads. New mod
-- IDs still enter this category proxy after registration is finalized.
local catalog = require("ids.catalog")
local categories = require("constants.catalog")

local ids = catalog.registered(categories.RU_SACRIFICES)

local source = {
    PURITY = "ABIL_RU_SACRIFICE_PURITY",
    WORDS = "ABIL_RU_SACRIFICE_WORDS",
    DRINK = "ABIL_RU_SACRIFICE_DRINK",
    ESSENCE = "ABIL_RU_SACRIFICE_ESSENCE",
    HEALTH = "ABIL_RU_SACRIFICE_HEALTH",
    STEALTH = "ABIL_RU_SACRIFICE_STEALTH",
    ARTIFICE = "ABIL_RU_SACRIFICE_ARTIFICE",
    LOVE = "ABIL_RU_SACRIFICE_LOVE",
    COURAGE = "ABIL_RU_SACRIFICE_COURAGE",
    ARCANA = "ABIL_RU_SACRIFICE_ARCANA",
    NIMBLENESS = "ABIL_RU_SACRIFICE_NIMBLENESS",
    DURABILITY = "ABIL_RU_SACRIFICE_DURABILITY",
    HAND = "ABIL_RU_SACRIFICE_HAND",
    EXPERIENCE = "ABIL_RU_SACRIFICE_EXPERIENCE",
    SKILL = "ABIL_RU_SACRIFICE_SKILL",
    EYE = "ABIL_RU_SACRIFICE_EYE",
    RESISTANCE = "ABIL_RU_SACRIFICE_RESISTANCE",
}

for name, id in pairs(source) do
    ids[name] = id
end

return ids
