-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1603

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DREAMSHARD_NECKLACE,
    name = "dreamshard necklace",
    source_order = 118,
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Dream",
    description =
        "It shatters if its wearer takes lethal or near-lethal damage,\npreventing the blow and releasing protectiv" ..
        "e dreams that heal and fight\nfor the wearer.",
    brand_description = "",
    colour = "ETC_SILVER",
    tile = "urand_dreamshard",
    tile_equipment = "",
    type = "",
    flags = {
        "drain",
        "special",
    },
    properties = {
        value = 2000,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
