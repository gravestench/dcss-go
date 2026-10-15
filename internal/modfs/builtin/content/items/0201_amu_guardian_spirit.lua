-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 786

local categories = require("constants.catalog")

local definition = {
    id = "AMU_GUARDIAN_SPIRIT",
    name = "amulet of guardian spirit",
    glyph = 34,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 44,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:786
    naming = {
        text = "amulet of guardian spirit",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
