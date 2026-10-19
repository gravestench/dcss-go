-- ring of Shadows (artefact_ids.UNRAND_SHADOWS) is a unique artefact based on
-- item_ids.RING_STEALTH.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_SHADOWS,
    name = "ring of Shadows",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.RING_STEALTH,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Umbra",
    description =
        "It surrounds you with an aura of shadow, increasing your stealth and\nreducing the accuracy of all others " ..
        "within it.",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_shadows",
    tile_equipment = "",
    type = "",
    flags = {
        "inv",
    },
    -- ring of Shadows properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
