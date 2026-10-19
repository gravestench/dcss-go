-- trishula \"Condemnation\ (artefact_ids.UNRAND_CONDEMNATION) is a unique
-- artefact based on item_ids.WPN_TRISHULA.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_CONDEMNATION,
    name = "trishula \"Condemnation\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_TRISHULA,
    fallback = "",
    brand = brands.HOLY_WRATH,
    fallback_brand = "",
    appearance = "",
    inscription = "anguish,",
    description = "",
    brand_description = "It inflicts anguish, making its victims' attacks reflect back on\nthem.",
    colour = "ETC_HOLY",
    tile = "urand_condemnation",
    tile_equipment = "condemnation",
    type = "",
    flags = {
        "fly",
        "noises",
    },
    -- trishula \"Condemnation\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        life = 1,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
