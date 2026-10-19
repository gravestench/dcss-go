-- sword of Cerebov (artefact_ids.UNRAND_CEREBOV) is a unique artefact based
-- on item_ids.WPN_GREAT_SWORD.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_CEREBOV,
    name = "sword of Cerebov",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_SWORD,
    fallback = "",
    brand = brands.FLAMING,
    fallback_brand = "",
    appearance = "great serpentine sword",
    inscription = "",
    description = "",
    brand_description = "It temporarily reduces the fire resistance of those it strikes.",
    colour = "ETC_FIRE",
    tile = "spwpn_sword_of_cerebov",
    tile_equipment = "sword_twist",
    type = "flamberge",
    flags = {
        "evil",
        "nogen",
    },
    -- sword of Cerebov properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        base_acc = 1,
        base_dam = 1,
        plus = 6,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
