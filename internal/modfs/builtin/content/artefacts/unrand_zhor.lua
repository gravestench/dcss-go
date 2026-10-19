-- skin of Zhor (artefact_ids.UNRAND_ZHOR) is a unique artefact based on
-- item_ids.ARM_ANIMAL_SKIN.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ZHOR,
    name = "skin of Zhor",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ANIMAL_SKIN,
    fallback = {
        class = classes.OBJ_ARMOUR,
        kind_id = item_ids.ARM_STEAM_DRAGON_ARMOUR,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Englaciate",
    description = "It radiates cold, occasionally slowing all nearby creatures who are\nnot resistant to cold.",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_zhor",
    tile_equipment = "zhor",
    type = "",
    flags = {
        "seeinv",
    },
    -- skin of Zhor properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        cold = 3,
        plus = 4,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
