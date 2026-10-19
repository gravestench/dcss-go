-- amulet of the Air (artefact_ids.UNRAND_AIR) is a unique artefact based on
-- item_ids.AMU_NOTHING.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_AIR,
    name = "amulet of the Air",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Inacc Air",
    description = "It reduces the accuracy of all your attacks.\n+It enhances your air magic.",
    brand_description = "",
    colour = "ETC_ELECTRICITY",
    tile = "urand_air",
    tile_equipment = "",
    type = "",
    flags = {
        "elec",
        "fly",
        "rmsl",
    },
    -- amulet of the Air properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
