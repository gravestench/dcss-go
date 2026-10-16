-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1249

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local sentinels = require("constants.artefact_base_sentinels")

local definition = {
    id = artefact_ids.UNRAND_OCTOPUS_KING_RING,
    name = "ring of the Octopus King",
    source_order = 90,
    class = classes.OBJ_JEWELLERY,
    kind_id = sentinels.RANDOM_RING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_WATER",
    tile = "urand_octoring",
    tile_equipment = "",
    type = "",
    flags = {
        "unided",
        "no_upgrade",
    },
    properties = {
        ac = 2,
        ev = 2,
        hp = 2,
        sh = 2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
