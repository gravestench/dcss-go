-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1525

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_THERMIC_ENGINE,
    name = "Maxwell's thermic engine",
    source_order = 112,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DOUBLE_SWORD,
    fallback = "",
    brand = brands.FLAMING,
    fallback_brand = "",
    appearance = "",
    inscription = "freeze,",
    description = "It becomes more effective when it hits something. This effect fades\nover time.",
    brand_description =
        "It freezes those it strikes, dealing additional cold damage. It can\nalso slow down cold-blooded creatures" ..
        ".",
    colour = "ETC_VEHUMET",
    tile = "urand_thermic_engine",
    tile_equipment = "thermic_engine",
    type = "",
    flags = {
    },
    properties = {
        plus = 2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
