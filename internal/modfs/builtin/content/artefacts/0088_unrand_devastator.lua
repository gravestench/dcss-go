-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1219

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_DEVASTATOR,
    name = "shillelagh \"Devastator\"",
    source_order = 88,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_CLUB,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_EVENINGSTAR,
    },
    brand = "",
    fallback_brand = brands.VORPAL,
    appearance = "",
    inscription = "shatter",
    description = "",
    brand_description =
        "It releases a powerful concussive burst when it strikes, dealing\nextra damage to the target and all other" ..
        " foes adjacent to them.",
    colour = "WHITE",
    tile = "urand_shillelagh",
    tile_equipment = "shillelagh",
    type = "shillelagh",
    flags = {
        "special",
    },
    properties = {
        base_dam = 3,
        plus = 6,
        value = 600,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
