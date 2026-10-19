-- Throatcutter (artefact_ids.UNRAND_THROATCUTTER) is a unique artefact based
-- on item_ids.WPN_LONG_SWORD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_THROATCUTTER,
    name = "Throatcutter",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LONG_SWORD,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_SCIMITAR,
    },
    brand = brands.DRAINING,
    fallback_brand = "",
    appearance = "",
    inscription = "coup de grace",
    description = "",
    brand_description = "It may instantly kill foes which have little health.",
    colour = "LIGHTRED",
    tile = "urand_throatcutter",
    tile_equipment = "throatcutter",
    type = "",
    flags = {
    },
    -- Throatcutter properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 7,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 9,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
