-- hood of the Assassin (artefact_ids.UNRAND_HOOD_ASSASSIN) is a unique
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
    id = artefact_ids.UNRAND_HOOD_ASSASSIN,
    name = "hood of the Assassin",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = armour_egos.SEE_INVISIBLE,
    appearance = "",
    inscription = "Detection Stab+",
    description =
        "It allows the wearer to sense nearby creatures.\n+It allows the wearer to make particularly effective stab" ..
        "bing attacks against\nhelpless or unaware enemies with any weapon.",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_hood_assassin",
    tile_equipment = "hood_assassin",
    type = "",
    flags = {
    },
    -- hood of the Assassin properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 2,
        stealth = 2,
        value = 600,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
