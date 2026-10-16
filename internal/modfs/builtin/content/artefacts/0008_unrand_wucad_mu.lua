-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:269

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_WUCAD_MU,
    name = "staff of Wucad Mu",
    source_order = 8,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*channel",
    description =
        "It occasionally powers its wielder's spells, but with a chance of\ncausing confusion or draining the wield" ..
        "er's intelligence.\n+It becomes more likely to activate and less likely to backfire with increased\nEvocat" ..
        "ions skill.",
    brand_description = "",
    colour = "ETC_MAGIC",
    tile = "spwpn_wucad_mu",
    tile_equipment = "wucad_mu",
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
