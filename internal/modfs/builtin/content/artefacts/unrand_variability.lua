-- mace of Variability (artefact_ids.UNRAND_VARIABILITY) is a unique artefact
-- based on item_ids.WPN_GREAT_MACE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local sentinels = require("constants.artefact_base_sentinels")

local definition = {
    id = artefact_ids.UNRAND_VARIABILITY,
    name = "mace of Variability",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_MACE,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = sentinels.RANDOM_KIND,
    },
    brand = brands.CHAOS,
    fallback_brand = "",
    appearance = "",
    inscription = "chain chaos",
    description = "",
    brand_description =
        "Each time it hits an enemy it has a different, random effect.\n+\n+It occasionally unleashes arcs of chaos" ..
        " on nearby creatures upon striking a\nfoe.",
    colour = "ETC_RANDOM",
    tile = "spwpn_mace_of_variability",
    tile_equipment = "mace_of_variability",
    type = "",
    flags = {
        "skip_ego",
    },
    -- mace of Variability properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 7,
        value = 600,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
