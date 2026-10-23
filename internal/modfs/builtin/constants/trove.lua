-- Trove state and price vocabulary is shared by population, payment, travel,
-- save validation, and mods. A price is a value; only the ECS gate may change.
local trove = {
    ENTRY_FAMILY = "trove_entry",
    DESTINATION_FAMILY = "trove",
    PRICE_ITEM = "item",
    PRICE_RUNE = "rune",
    PRICE_NO_PIETY = "no_piety",
    MARKER_IDENTITY = "trove:toll",
    CLOSURE_NONE = "",
    CLOSURE_PAID = "paid",
    RUNE_SLIME_SOURCE_INDEX = 3,
    RUNE_ABYSSAL_SOURCE_INDEX = 11,
    PIETY_AFTER_PAYMENT = 15,
    MAX_PIETY = 200,
}

return trove
