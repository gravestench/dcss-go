-- ratskin cloak (artefact_ids.UNRAND_RATSKIN_CLOAK) is a unique artefact
-- based on item_ids.ARM_CLOAK.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_RATSKIN_CLOAK,
    name = "ratskin cloak",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CLOAK,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Rats",
    description = "When the wearer is hurt, rats may emerge from it to assist them.",
    brand_description = "",
    colour = "ETC_BEOGH",
    tile = "urand_ratskin_cloak",
    tile_equipment = "ratskin",
    type = "",
    flags = {
        "poison",
    },
    -- ratskin cloak properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        dex = 1,
        int = -1,
        life = 1,
        plus = 2,
        str = -1,
    },
    -- Depth 11 is a preference in unique.choose, not a hard cutoff: deeper
    -- rolls retain this cloak with lower reservoir weight.
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
