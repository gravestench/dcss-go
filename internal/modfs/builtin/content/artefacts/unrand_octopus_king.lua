-- trident of the Octopus King (artefact_ids.UNRAND_OCTOPUS_KING) is a unique
-- artefact based on item_ids.WPN_TRIDENT.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_OCTOPUS_KING,
    name = "trident of the Octopus King",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_TRIDENT,
    fallback = "",
    brand = brands.VENOM,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_WATER",
    tile = "urand_octopus_king",
    tile_equipment = "trident_octopus_king",
    type = "",
    flags = {
        "elec",
        "poison",
        "no_upgrade",
    },
    -- trident of the Octopus King properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 8,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
