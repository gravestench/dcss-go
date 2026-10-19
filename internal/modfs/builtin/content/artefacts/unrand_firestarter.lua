-- great mace \"Firestarter\ (artefact_ids.UNRAND_FIRESTARTER) is a unique
-- artefact based on item_ids.WPN_GREAT_MACE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_FIRESTARTER,
    name = "great mace \"Firestarter\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_MACE,
    fallback = "",
    brand = brands.FLAMING,
    fallback_brand = "",
    appearance = "",
    inscription = "inner flame,",
    description = "It grants immunity to clouds of flame.",
    brand_description =
        "It burns those it strikes, dealing additional fire damage.\n+\n+It fills those it strikes with an explosiv" ..
        "e inner flame.",
    colour = "RED",
    tile = "urand_firestarter",
    tile_equipment = "firestarter",
    type = "",
    flags = {
        "skip_ego",
    },
    -- great mace \"Firestarter\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        fire = 2,
        plus = 7,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
