-- hat of the Alchemist (artefact_ids.UNRAND_ALCHEMIST) is a unique artefact
-- based on item_ids.ARM_HAT.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ALCHEMIST,
    name = "hat of the Alchemist",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTMAGENTA",
    tile = "urand_alchemist",
    tile_equipment = "turban_purple",
    type = "",
    flags = {
        "elec",
        "poison",
        "rMut",
        "rCorr",
    },
    -- hat of the Alchemist properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        cold = 1,
        fire = 1,
        life = 1,
        plus = -2,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
