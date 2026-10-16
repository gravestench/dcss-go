-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:254

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_OLGREB,
    name = "staff of Olgreb",
    source_order = 7,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "rPois∞",
    description =
        "It enhances your poison magic.\n+It grants immunity to poison.\n+It can be activated via the 'a'bility men" ..
        "u to radiate toxic energy, with\neffectiveness depending on Evocations skill.",
    brand_description =
        "If the wielder is skilled in Evocations, they can envenom those struck\nby it, dealing poison damage which" ..
        " bypasses armour.",
    colour = "ETC_POISON",
    tile = "spwpn_staff_of_olgreb",
    tile_equipment = "olgreb",
    type = "",
    flags = {
    },
    properties = {
        plus = 9,
        value = 1000,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
