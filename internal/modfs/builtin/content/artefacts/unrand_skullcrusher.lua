-- giant club \"Skullcrusher\ (artefact_ids.UNRAND_SKULLCRUSHER) is a unique
-- artefact based on item_ids.WPN_GIANT_CLUB.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_SKULLCRUSHER,
    name = "giant club \"Skullcrusher\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GIANT_CLUB,
    fallback = "",
    brand = brands.SPEED,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_skullcrusher",
    tile_equipment = "giant_club_slant",
    type = "",
    flags = {
    },
    -- giant club \"Skullcrusher\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 3,
        str = 7,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
