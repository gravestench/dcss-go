-- demon trident \"Rift\ (artefact_ids.UNRAND_RIFT) is a unique artefact based
-- on item_ids.WPN_DEMON_TRIDENT.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_RIFT,
    name = "demon trident \"Rift\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DEMON_TRIDENT,
    fallback = "",
    brand = brands.DISTORTION,
    fallback_brand = "",
    appearance = "",
    inscription = "reach+",
    description = "",
    brand_description = "It can reach especially far, and its reaching attacks ignore other\ncreatures in the way.",
    colour = "ETC_WARP",
    tile = "urand_rift",
    tile_equipment = "rift",
    type = "",
    flags = {
    },
    -- demon trident \"Rift\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
