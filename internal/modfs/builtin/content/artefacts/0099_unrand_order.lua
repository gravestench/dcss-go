-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1356

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ORDER,
    name = "lajatang of Order",
    source_order = 99,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LAJATANG,
    fallback = "",
    brand = "",
    fallback_brand = brands.HOLY_WRATH,
    appearance = "",
    inscription = "silver,",
    description = "",
    brand_description =
        "It inflicts extra damage upon those it strikes, and deals\nsubstantially increased damage to chaotic, muta" ..
        "ted and magically transformed\nbeings.",
    colour = "ETC_SILVER",
    tile = "urand_order",
    tile_equipment = "order",
    type = "",
    flags = {
        "rMut",
    },
    properties = {
        plus = 7,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
