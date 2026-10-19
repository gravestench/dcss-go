-- lance \"Wyrmbane\ (artefact_ids.UNRAND_WYRMBANE) is a unique artefact based
-- on item_ids.WPN_SPEAR.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_WYRMBANE,
    name = "lance \"Wyrmbane\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SPEAR,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_DEMON_TRIDENT,
    },
    brand = "",
    fallback_brand = brands.VORPAL,
    appearance = "",
    inscription = "slay drac,",
    description = "",
    brand_description = "It inflicts extra damage against dragons and draconians.",
    colour = "LIGHTGREEN",
    tile = "urand_wyrmbane",
    tile_equipment = "wyrmbane",
    type = "lance",
    flags = {
        "poison",
        "no_upgrade",
    },
    -- lance \"Wyrmbane\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        ac = 3,
        base_dam = 2,
        cold = 1,
        fire = 1,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
