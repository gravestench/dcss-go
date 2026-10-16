-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:282

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_VAMPIRES_TOOTH,
    name = "Vampire's Tooth",
    source_order = 9,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_QUICK_BLADE,
    fallback = "",
    brand = brands.VAMPIRISM,
    fallback_brand = brands.VAMPIRISM,
    appearance = "",
    inscription = "vamp",
    description = "",
    brand_description =
        "It occasionally heals its wielder for the full amount of damage dealt\nwhen it wounds a living foe.",
    colour = "ETC_BONE",
    tile = "spwpn_vampires_tooth",
    tile_equipment = "vampires_tooth",
    type = "",
    flags = {
        "skip_ego",
    },
    properties = {
        plus = 8,
        value = 600,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
