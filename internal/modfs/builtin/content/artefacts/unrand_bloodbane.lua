-- demon blade \"Bloodbane\ (artefact_ids.UNRAND_BLOODBANE) is a unique
-- artefact based on item_ids.WPN_DEMON_BLADE.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_BLOODBANE,
    name = "demon blade \"Bloodbane\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DEMON_BLADE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_bloodbane",
    tile_equipment = "bloodbane",
    type = "",
    flags = {
        "nogen",
    },
    -- demon blade \"Bloodbane\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        angry = 5,
        plus = 8,
        stealth = -1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
