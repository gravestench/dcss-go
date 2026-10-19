-- glaive of Prune (artefact_ids.UNRAND_PRUNE) is a unique artefact based on
-- item_ids.WPN_GLAIVE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_PRUNE,
    name = "glaive of Prune",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GLAIVE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "It halves damage taken while paralysed, petrified or unconscious.",
    brand_description = "",
    colour = "LIGHTMAGENTA",
    tile = "spwpn_glaive_of_prune",
    tile_equipment = "glaive_of_prune",
    type = "",
    flags = {
        "chaotic",
    },
    -- glaive of Prune properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 12,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
