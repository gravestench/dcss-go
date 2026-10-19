-- autumn katana (artefact_ids.UNRAND_AUTUMN_KATANA) is a unique artefact
-- based on item_ids.WPN_LONG_SWORD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_AUTUMN_KATANA,
    name = "autumn katana",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LONG_SWORD,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_DOUBLE_SWORD,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "vorpal, manifold assault",
    description = "It sometimes launches melee attacks against multiple visible enemies.",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_katana",
    tile_equipment = "katana_slant",
    type = "katana",
    flags = {
    },
    -- autumn katana properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        base_acc = 2,
        base_dam = 4,
        base_delay = -2,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
