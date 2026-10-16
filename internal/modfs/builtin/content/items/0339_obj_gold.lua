-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1209

local categories = require("constants.catalog")

local definition = {
    id = "OBJ_GOLD",
    name = "gold piece",
    -- Source vault expressions use the short spelling.
    vault_aliases = { "gold" },
    glyph = 36,
    class = "OBJ_GOLD",
    class_value = 13,
    subtype_value = 0,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:1209
    naming = {
        text = "gold piece",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
