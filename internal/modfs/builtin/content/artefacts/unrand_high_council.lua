-- hat of the High Council (artefact_ids.UNRAND_HIGH_COUNCIL) is a unique
-- artefact based on item_ids.ARM_HAT.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_HIGH_COUNCIL,
    name = "hat of the High Council",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = armour_egos.ARCHMAGI,
    fallback_brand = "",
    appearance = "",
    inscription = "Wiz-",
    description = "",
    brand_description = "",
    colour = "LIGHTGREEN",
    tile = "urand_high_council",
    tile_equipment = "wizard_lightgreen",
    type = "",
    flags = {
        "nogen",
    },
    -- hat of the High Council properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 2,
        stealth = -1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
