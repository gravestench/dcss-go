-- robe of Clouds (artefact_ids.UNRAND_RCLOUDS) is a unique artefact based on
-- item_ids.ARM_ROBE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_RCLOUDS,
    name = "robe of Clouds",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Thunder rCloud",
    description =
        "It occasionally creates storm clouds above nearby enemies.\n+It grants its wearer immunity to clouds.",
    brand_description = "",
    colour = "ETC_MIST",
    tile = "urand_clouds",
    tile_equipment = "robe_clouds",
    type = "",
    flags = {
        "elec",
    },
    -- robe of Clouds properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
