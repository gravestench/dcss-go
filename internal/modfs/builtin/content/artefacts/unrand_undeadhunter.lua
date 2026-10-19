-- great mace \"Undeadhunter\ (artefact_ids.UNRAND_UNDEADHUNTER) is a unique
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
    id = artefact_ids.UNRAND_UNDEADHUNTER,
    name = "great mace \"Undeadhunter\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_MACE,
    fallback = "",
    brand = "",
    fallback_brand = brands.HOLY_WRATH,
    appearance = "",
    inscription = "disrupt,",
    description = "",
    brand_description = "It inflicts significantly more damage against the undead.",
    colour = "LIGHTGREY",
    tile = "urand_undeadhunter",
    tile_equipment = "undeadhunter",
    type = "",
    flags = {
    },
    -- great mace \"Undeadhunter\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        life = 1,
        plus = 7,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
