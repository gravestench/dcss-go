-- mithril axe \"Arga\ (artefact_ids.UNRAND_ARGA) is a unique artefact based
-- on item_ids.WPN_BROAD_AXE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ARGA,
    name = "mithril axe \"Arga\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BROAD_AXE,
    fallback = "",
    brand = brands.SPEED,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "WHITE",
    tile = "urand_arga",
    tile_equipment = "arga",
    type = "",
    flags = {
    },
    -- mithril axe \"Arga\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 8,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
