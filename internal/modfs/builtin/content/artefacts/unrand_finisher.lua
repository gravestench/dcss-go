-- scythe \"Finisher\ (artefact_ids.UNRAND_FINISHER) is a unique artefact
-- based on item_ids.WPN_HALBERD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_FINISHER,
    name = "scythe \"Finisher\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_HALBERD,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_BARDICHE,
    },
    brand = brands.SPEED,
    fallback_brand = "",
    appearance = "",
    inscription = "eviscerate",
    description = "",
    brand_description =
        "It may eviscerate those it strikes, slaying them instantly, with a\ndecreasing chance against stronger foe" ..
        "s.",
    colour = "ETC_DARK",
    tile = "urand_finisher",
    tile_equipment = "finisher",
    type = "scythe",
    flags = {
    },
    -- scythe \"Finisher\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        base_dam = 1,
        base_delay = 5,
        plus = 5,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
