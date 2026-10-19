-- necklace of Bloodlust (artefact_ids.UNRAND_BLOODLUST) is a unique artefact
-- based on item_ids.AMU_NOTHING.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_BLOODLUST,
    name = "necklace of Bloodlust",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "It extends the wearer's berserk rage when killing foes.",
    brand_description = "",
    colour = "ETC_BLOOD",
    tile = "urand_bloodlust",
    tile_equipment = "",
    type = "",
    flags = {
    },
    -- necklace of Bloodlust properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        angry = 50,
        int = -3,
        slay = 6,
        will = 2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
