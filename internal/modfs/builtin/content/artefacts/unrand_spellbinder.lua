-- demon whip \"Spellbinder\ (artefact_ids.UNRAND_SPELLBINDER) is a unique
-- artefact based on item_ids.WPN_DEMON_WHIP.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_SPELLBINDER,
    name = "demon whip \"Spellbinder\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DEMON_WHIP,
    fallback = "",
    brand = brands.ANTIMAGIC,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description =
        "It unleashes wild and unpredictable magical effects upon striking\na wizard or a creature with magical abi" ..
        "lities.",
    colour = "ETC_ENCHANT",
    tile = "urand_spellbinder",
    tile_equipment = "spellbinder",
    type = "",
    flags = {
    },
    -- demon whip \"Spellbinder\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 5,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
