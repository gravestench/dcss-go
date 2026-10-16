-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1315

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_HIGH_COUNCIL,
    name = "hat of the High Council",
    source_order = 96,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = armour_egos.ARCHMAGI,
    fallback_brand = "",
    appearance = "",
    inscription = "Wiz-",
    description = "",
    brand_description = "",
    colour = "LIGHTGREEN",
    tile = "urand_high_council",
    tile_equipment = "wizard_lightgreen",
    type = "",
    flags = {
        "nogen",
    },
    properties = {
        plus = 2,
        stealth = -1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
