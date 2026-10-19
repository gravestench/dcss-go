-- eveningstar \"Brilliance\ (artefact_ids.UNRAND_BRILLIANCE) is a unique
-- artefact based on item_ids.WPN_EVENINGSTAR.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_BRILLIANCE,
    name = "eveningstar \"Brilliance\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_EVENINGSTAR,
    fallback = "",
    brand = brands.HOLY_WRATH,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_HOLY",
    tile = "urand_brilliance",
    tile_equipment = "mace_of_brilliance",
    type = "",
    flags = {
        "nogen",
    },
    -- eveningstar \"Brilliance\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        ac = 5,
        int = 5,
        life = 1,
        plus = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
