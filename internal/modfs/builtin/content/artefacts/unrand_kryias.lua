-- Kryia's mail coat (artefact_ids.UNRAND_KRYIAS) is a unique artefact based
-- on item_ids.ARM_SCALE_MAIL.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_KRYIAS,
    name = "Kryia's mail coat",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_SCALE_MAIL,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "PotionHeal*2",
    description = "Potions are twice as effective at healing its wearer.",
    brand_description = "",
    colour = "LIGHTCYAN",
    tile = "urand_kryias",
    tile_equipment = "kryias",
    type = "",
    flags = {
    },
    -- Kryia's mail coat properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        cold = 1,
        plus = 7,
        value = 600,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
