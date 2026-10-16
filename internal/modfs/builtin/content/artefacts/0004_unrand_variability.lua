-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:216

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local sentinels = require("constants.artefact_base_sentinels")

local definition = {
    id = artefact_ids.UNRAND_VARIABILITY,
    name = "mace of Variability",
    source_order = 4,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_MACE,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = sentinels.RANDOM_KIND,
    },
    brand = brands.CHAOS,
    fallback_brand = "",
    appearance = "",
    inscription = "chain chaos",
    description = "",
    brand_description =
        "Each time it hits an enemy it has a different, random effect.\n+\n+It occasionally unleashes arcs of chaos" ..
        " on nearby creatures upon striking a\nfoe.",
    colour = "ETC_RANDOM",
    tile = "spwpn_mace_of_variability",
    tile_equipment = "mace_of_variability",
    type = "",
    flags = {
        "skip_ego",
    },
    properties = {
        plus = 7,
        value = 600,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
