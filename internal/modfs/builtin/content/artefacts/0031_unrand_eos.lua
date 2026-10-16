-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:564

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_EOS,
    name = "morningstar \"Eos\"",
    source_order = 31,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_MORNINGSTAR,
    fallback = "",
    brand = brands.ELECTROCUTION,
    fallback_brand = "",
    appearance = "",
    inscription = "Halo",
    description =
        "It grants its wielder a halo, revealing invisible creatures and\nincreasing accuracy against all within it" ..
        " other than the wielder.",
    brand_description = "",
    colour = "ETC_JEWEL",
    tile = "urand_eos",
    tile_equipment = "eos",
    type = "",
    flags = {
        "elec",
    },
    properties = {
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
