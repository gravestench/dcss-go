-- scimitar of Flaming Death (artefact_ids.UNRAND_FLAMING_DEATH) is a unique
-- artefact based on item_ids.WPN_SCIMITAR.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_FLAMING_DEATH,
    name = "scimitar of Flaming Death",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SCIMITAR,
    fallback = "",
    brand = brands.FLAMING,
    fallback_brand = "",
    appearance = "",
    inscription = "sticky flame,",
    description = "",
    brand_description = "",
    colour = "ETC_FIRE",
    tile = "urand_flaming_death",
    tile_equipment = "flaming_death",
    type = "",
    flags = {
        "poison",
        "skip_ego",
        "nogen",
    },
    -- scimitar of Flaming Death properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        cold = -1,
        fire = 2,
        plus = 6,
        will = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
