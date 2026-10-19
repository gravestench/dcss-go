-- pair of quick blades \"Gyre\" and \"Gimble\ (artefact_ids.UNRAND_GYRE) is a
-- unique artefact based on item_ids.WPN_QUICK_BLADE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_GYRE,
    name = "pair of quick blades \"Gyre\" and \"Gimble\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_QUICK_BLADE,
    fallback = "",
    brand = brands.PROTECTION,
    fallback_brand = brands.VORPAL,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_ENCHANT",
    tile = "urand_gyre",
    tile_equipment = "gyre",
    type = "pair of quick blades",
    flags = {
    },
    -- pair of quick blades \"Gyre\" and \"Gimble\ properties are projected into
    -- equipment effects; avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 12,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
