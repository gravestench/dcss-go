-- arc blade (artefact_ids.UNRAND_ARC_BLADE) is a unique artefact based on
-- item_ids.WPN_RAPIER.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ARC_BLADE,
    name = "arc blade",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_RAPIER,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_QUICK_BLADE,
    },
    brand = "",
    fallback_brand = brands.ELECTROCUTION,
    appearance = "",
    inscription = "discharge,",
    description = "",
    brand_description =
        "It occasionally unleashes powerful arcs of lightning upon striking a\nfoe. These may arc to other adjacent" ..
        " creatures (including the wielder, but\ndealing reduced damage to them) before grounding out.",
    colour = "ETC_ELECTRICITY",
    tile = "urand_arc_blade",
    tile_equipment = "arc_blade",
    type = "",
    flags = {
        "elec",
    },
    -- arc blade properties are projected into equipment effects; avoid duplicating
    -- a wearer-only flag on the item entity.
    properties = {
        plus = 8,
        value = 600,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
