-- amulet of Vitality (artefact_ids.UNRAND_VITALITY) is a unique artefact
-- based on item_ids.AMU_MANA_REGENERATION.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_VITALITY,
    name = "amulet of Vitality",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_MANA_REGENERATION,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "RegenMP++",
    description = "",
    brand_description = "",
    colour = "ETC_MUTAGENIC",
    tile = "urand_vitality",
    tile_equipment = "",
    type = "",
    flags = {
        "skip_ego",
        "evil",
    },
    -- amulet of Vitality properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        regen = 2,
        value = 1000,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
