-- heavy crossbow \"Sniper\ (artefact_ids.UNRAND_SNIPER) is a unique artefact
-- based on item_ids.WPN_TRIPLE_CROSSBOW.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_SNIPER,
    name = "heavy crossbow \"Sniper\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_TRIPLE_CROSSBOW,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "Acc+∞",
    description = "Any ammunition fired from it never misses its target.",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_sniper",
    tile_equipment = "sniper",
    type = "heavy crossbow",
    flags = {
        "seeinv",
    },
    -- heavy crossbow \"Sniper\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        base_delay = 4,
        plus = 9,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
