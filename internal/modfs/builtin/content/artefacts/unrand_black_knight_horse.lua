-- Black Knight's barding (artefact_ids.UNRAND_BLACK_KNIGHT_HORSE) is a unique
-- artefact based on item_ids.ARM_BARDING.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_BLACK_KNIGHT_HORSE,
    name = "Black Knight's barding",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BARDING,
    fallback = "",
    brand = armour_egos.PONDEROUSNESS,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_UNHOLY",
    tile = "urand_bk_barding",
    tile_equipment = "black_knight",
    type = "",
    flags = {
        "poison",
        "evil",
    },
    -- Black Knight's barding properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        life = 1,
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
