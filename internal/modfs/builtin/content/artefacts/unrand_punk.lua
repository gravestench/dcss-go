-- greatsling \"Punk\ (artefact_ids.UNRAND_PUNK) is a unique artefact based on
-- item_ids.WPN_SLING.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_PUNK,
    name = "greatsling \"Punk\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SLING,
    fallback = "",
    brand = brands.ACID,
    fallback_brand = brands.NORMAL,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_SLIME",
    tile = "urand_punk",
    tile_equipment = "punk",
    type = "greatsling",
    flags = {
        "rCorr",
    },
    -- greatsling \"Punk\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        base_dam = 3,
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
