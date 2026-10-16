-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:426

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_LEECH,
    name = "demon blade \"Leech\"",
    source_order = 20,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DEMON_BLADE,
    fallback = "",
    brand = brands.VAMPIRISM,
    fallback_brand = "",
    appearance = "",
    inscription = "vamp,",
    description = "",
    brand_description = "It heals its wielder for a portion of the damage dealt every time it\nstrikes a living foe.",
    colour = "ETC_DARK",
    tile = "urand_leech",
    tile_equipment = "leech",
    type = "",
    flags = {
        "drain",
        "harm",
        "skip_ego",
    },
    properties = {
        life = 1,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
