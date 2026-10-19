-- crown of Eternal Torment (artefact_ids.UNRAND_ETERNAL_TORMENT) is a unique
-- artefact based on item_ids.ARM_HAT.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ETERNAL_TORMENT,
    name = "crown of Eternal Torment",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "rTorment HP--",
    description = "",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_eternal_torment",
    tile_equipment = "eternal_torment",
    type = "",
    flags = {
        "evil",
        "seeinv",
        "nogen",
        "drain",
    },
    -- crown of Eternal Torment properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        life = 3,
        plus = 3,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
