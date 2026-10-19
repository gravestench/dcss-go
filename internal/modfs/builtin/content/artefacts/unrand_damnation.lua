-- arbalest \"Damnation\ (artefact_ids.UNRAND_DAMNATION) is a unique artefact
-- based on item_ids.WPN_ARBALEST.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_DAMNATION,
    name = "arbalest \"Damnation\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_ARBALEST,
    fallback = "",
    brand = "",
    fallback_brand = brands.FLAMING,
    appearance = "",
    inscription = "damnation",
    description = "",
    brand_description =
        "Any ammunition fired from it explodes in a burst of damnation on\nstriking a foe, dealing damage which byp" ..
        "asses armour.",
    colour = "ETC_FIRE",
    tile = "urand_damnation",
    tile_equipment = "crossbow_fire",
    type = "",
    flags = {
        "evil",
    },
    -- arbalest \"Damnation\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 6,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
