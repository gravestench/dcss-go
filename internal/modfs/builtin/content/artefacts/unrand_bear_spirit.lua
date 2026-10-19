-- hat of the Bear Spirit (artefact_ids.UNRAND_BEAR_SPIRIT) is a unique
-- artefact based on item_ids.ARM_HAT.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_BEAR_SPIRIT,
    name = "hat of the Bear Spirit",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = armour_egos.SPIRIT_SHIELD,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "Going berserk makes the wearer tougher, and they're slowed less afterward.",
    colour = "DARKGREY",
    tile = "urand_bear",
    tile_equipment = "bear",
    type = "",
    flags = {
    },
    -- hat of the Bear Spirit properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        angry = 20,
        plus = 2,
        will = 2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
