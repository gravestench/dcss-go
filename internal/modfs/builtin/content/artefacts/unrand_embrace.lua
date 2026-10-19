-- Cigotuvi's embrace (artefact_ids.UNRAND_EMBRACE) is a unique artefact based
-- on item_ids.ARM_LEATHER_ARMOUR.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_EMBRACE,
    name = "Cigotuvi's embrace",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_LEATHER_ARMOUR,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "rMiasma",
    description =
        "It gathers nearby corpses to temporarily increase the armour it\nprovides.\n+It protects you from foul pes" ..
        "tilence.",
    brand_description = "",
    colour = "ETC_UNHOLY",
    tile = "urand_cigotuvi",
    tile_equipment = "bplate_green",
    type = "",
    flags = {
        "drain",
        "evil",
        "special",
        "no_upgrade",
    },
    -- Cigotuvi's embrace properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        life = 1,
        plus = 4,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
