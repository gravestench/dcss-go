-- staff of the Meek (artefact_ids.UNRAND_MEEK) is a unique artefact based on
-- item_ids.WPN_QUARTERSTAFF.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_MEEK,
    name = "staff of the Meek",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_QUARTERSTAFF,
    fallback = "",
    brand = brands.PROTECTION,
    fallback_brand = "",
    appearance = "",
    inscription = "meekguard",
    description = "",
    brand_description = "It provides extra protection to wielders with little health.",
    colour = "WHITE",
    tile = "urand_meek",
    tile_equipment = "staff_mage_two",
    type = "",
    flags = {
    },
    -- staff of the Meek properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 7,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
