-- shield of the Gong (artefact_ids.UNRAND_GONG) is a unique artefact based on
-- item_ids.ARM_KITE_SHIELD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_GONG,
    name = "shield of the Gong",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_KITE_SHIELD,
    fallback = {
        class = classes.OBJ_ARMOUR,
        kind_id = item_ids.ARM_TOWER_SHIELD,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "It is deafeningly noisy when blocking attacks.",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "urand_gong",
    tile_equipment = "kite_shield_gong",
    type = "",
    flags = {
        "elec",
    },
    -- shield of the Gong properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        ev = -5,
        life = 1,
        plus = 18,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
