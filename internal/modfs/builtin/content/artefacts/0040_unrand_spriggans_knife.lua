-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:686

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_SPRIGGANS_KNIFE,
    name = "Spriggan's Knife",
    source_order = 40,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DAGGER,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "stab,",
    description =
        "It is more effective when stabbing unaware enemies, sometimes treating\nthem as though they were completel" ..
        "y helpless.",
    brand_description = "",
    colour = "LIGHTCYAN",
    tile = "urand_spriggans_knife",
    tile_equipment = "spriggans_knife",
    type = "knife",
    flags = {
    },
    properties = {
        ev = 4,
        plus = 7,
        stealth = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
