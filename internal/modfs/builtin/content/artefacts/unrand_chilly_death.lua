-- dagger of Chilly Death (artefact_ids.UNRAND_CHILLY_DEATH) is a unique
-- artefact based on item_ids.WPN_DAGGER.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_CHILLY_DEATH,
    name = "dagger of Chilly Death",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DAGGER,
    fallback = "",
    brand = brands.FREEZING,
    fallback_brand = "",
    appearance = "",
    inscription = "flash freeze,",
    description = "",
    brand_description = "",
    colour = "ETC_ICE",
    tile = "urand_chilly_death",
    tile_equipment = "chilly_death",
    type = "",
    flags = {
        "poison",
        "skip_ego",
        "nogen",
    },
    -- dagger of Chilly Death properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        cold = 2,
        fire = -1,
        plus = 9,
        will = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
