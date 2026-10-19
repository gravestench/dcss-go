-- salamander hide armour (artefact_ids.UNRAND_SALAMANDER) is a unique
-- artefact based on item_ids.ARM_LEATHER_ARMOUR.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_SALAMANDER,
    name = "salamander hide armour",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_LEATHER_ARMOUR,
    fallback = "",
    brand = "",
    fallback_brand = armour_egos.FIRE_RESISTANCE,
    appearance = "",
    inscription = "Flames",
    description =
        "It surrounds you with a cloud of flames.\n+It grants immunity to clouds of flame.\n+It enhances your fire " ..
        "magic.",
    brand_description = "",
    colour = "ETC_FIRE",
    tile = "urand_salamander",
    tile_equipment = "leather_red",
    type = "",
    flags = {
        "special",
    },
    -- salamander hide armour properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        cold = -2,
        fire = 2,
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
