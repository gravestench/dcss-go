-- seven-league boots (artefact_ids.UNRAND_SEVEN_LEAGUE_BOOTS) is a unique
-- artefact based on item_ids.ARM_BOOTS.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_SEVEN_LEAGUE_BOOTS,
    name = "seven-league boots",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BOOTS,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Rampage+∞",
    description = "Its wearer moves as far as possible in that direction when moving\ntowards enemies.",
    brand_description = "",
    colour = "ETC_ENCHANT",
    tile = "urand_seven_league_boots",
    tile_equipment = "seven_league_boots",
    type = "",
    flags = {
    },
    -- seven-league boots properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 3,
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
