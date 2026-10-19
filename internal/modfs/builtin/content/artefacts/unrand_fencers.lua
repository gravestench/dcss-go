-- fencer's gloves (artefact_ids.UNRAND_FENCERS) is a unique artefact based on
-- item_ids.ARM_GLOVES.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_FENCERS,
    name = "fencer's gloves",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_GLOVES,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Riposte",
    description =
        "It allows the wearer to riposte with melee\nweapons, swiftly retaliating against missed or blocked melee a" ..
        "ttacks.",
    brand_description = "",
    colour = "WHITE",
    tile = "urand_fencer",
    tile_equipment = "glove_white",
    type = "",
    flags = {
    },
    -- fencer's gloves properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        dex = 3,
        plus = 0,
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
