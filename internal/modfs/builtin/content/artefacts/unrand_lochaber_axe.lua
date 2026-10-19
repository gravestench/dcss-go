-- lochaber axe (artefact_ids.UNRAND_LOCHABER_AXE) is a unique artefact based
-- on item_ids.WPN_BARDICHE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_LOCHABER_AXE,
    name = "lochaber axe",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BARDICHE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "reach-cleave, poleaxe",
    description = "",
    brand_description =
        "It can be evoked to extend its reach, and strikes at all foes within reach, dealing less damage to those n" ..
        "ot targeted.\n+It uses either Axes or Polearms skill, whichever is higher.",
    colour = "ETC_IRON",
    tile = "urand_lochaber_axe",
    tile_equipment = "lochaber_axe",
    type = "lochaber axe",
    flags = {
    },
    -- lochaber axe properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        base_acc = -1,
        base_dam = 1,
        base_delay = 1,
        plus = 5,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
