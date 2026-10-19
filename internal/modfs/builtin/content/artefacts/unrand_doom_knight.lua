-- sword of the Doom Knight (artefact_ids.UNRAND_DOOM_KNIGHT) is a unique
-- artefact based on item_ids.WPN_GREAT_SWORD.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_DOOM_KNIGHT,
    name = "sword of the Doom Knight",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_SWORD,
    fallback = "",
    brand = brands.PAIN,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BLUE",
    tile = "urand_doom_knight",
    tile_equipment = "doom_knight",
    type = "",
    flags = {
        "nospell",
        "nogen",
    },
    -- sword of the Doom Knight properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 13,
        will = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
