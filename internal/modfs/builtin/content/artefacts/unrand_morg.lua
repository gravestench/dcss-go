-- dagger \"Morg\ (artefact_ids.UNRAND_MORG) is a unique artefact based on
-- item_ids.WPN_DAGGER.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_MORG,
    name = "dagger \"Morg\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DAGGER,
    fallback = "",
    brand = brands.PAIN,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_morg",
    tile_equipment = "morg",
    type = "",
    flags = {
    },
    -- dagger \"Morg\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        int = 5,
        plus = 4,
        will = 1,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 9,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
