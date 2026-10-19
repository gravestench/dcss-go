-- storm bow (artefact_ids.UNRAND_STORM_BOW) is a unique artefact based on
-- item_ids.WPN_LONGBOW.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_STORM_BOW,
    name = "storm bow",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LONGBOW,
    fallback = "",
    brand = brands.ELECTROCUTION,
    fallback_brand = "",
    appearance = "",
    inscription = "penet",
    description = "",
    brand_description =
        "Any ammunition fired by it passes through the targets it hits,\npotentially hitting all targets in its pat" ..
        "h until it reaches maximum range.",
    colour = "BLUE",
    tile = "urand_storm_bow",
    tile_equipment = "storm_bow",
    type = "",
    flags = {
    },
    -- storm bow properties are projected into equipment effects; avoid duplicating
    -- a wearer-only flag on the item entity.
    properties = {
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
