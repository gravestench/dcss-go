-- longbow \"Piercer\ (artefact_ids.UNRAND_PIERCER) is a unique artefact based
-- on item_ids.WPN_LONGBOW.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_PIERCER,
    name = "longbow \"Piercer\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LONGBOW,
    fallback = "",
    brand = brands.PENETRATION,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "CYAN",
    tile = "urand_piercer",
    tile_equipment = "great_bow",
    type = "",
    flags = {
        "nogen",
    },
    -- longbow \"Piercer\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        ev = -2,
        plus = 7,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
