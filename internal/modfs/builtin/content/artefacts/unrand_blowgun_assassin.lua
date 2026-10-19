-- blowgun of the Assassin (artefact_ids.UNRAND_BLOWGUN_ASSASSIN) is a unique
-- artefact based on item_ids.WPN_BLOWGUN.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_BLOWGUN_ASSASSIN,
    name = "blowgun of the Assassin",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BLOWGUN,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_LONGBOW,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "stab,",
    description = "",
    brand_description = "",
    colour = "ETC_DEATH",
    tile = "urand_blowgun",
    tile_equipment = "blowgun",
    type = "",
    flags = {
        "inv",
        "tilerim",
        "nogen",
    },
    -- blowgun of the Assassin properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 6,
        stealth = 2,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
