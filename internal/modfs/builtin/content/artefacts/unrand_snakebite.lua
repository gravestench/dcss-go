-- whip \"Snakebite\ (artefact_ids.UNRAND_SNAKEBITE) is a unique artefact
-- based on item_ids.WPN_WHIP.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_SNAKEBITE,
    name = "whip \"Snakebite\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_WHIP,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_DEMON_WHIP,
    },
    brand = brands.VENOM,
    fallback_brand = "",
    appearance = "",
    inscription = "curare,",
    description = "",
    brand_description =
        "It occasionally inflicts asphyxiating poison on those it strikes,\ndealing poison damage and causing slown" ..
        "ess.",
    colour = "DARKGREY",
    tile = "urand_snakebite",
    tile_equipment = "snakebite",
    type = "",
    flags = {
        "poison",
    },
    -- whip \"Snakebite\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
