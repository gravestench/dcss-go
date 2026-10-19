-- Spriggan's Knife (artefact_ids.UNRAND_SPRIGGANS_KNIFE) is a unique artefact
-- based on item_ids.WPN_DAGGER.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_SPRIGGANS_KNIFE,
    name = "Spriggan's Knife",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DAGGER,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "stab,",
    description =
        "It is more effective when stabbing unaware enemies, sometimes treating\nthem as though they were completel" ..
        "y helpless.",
    brand_description = "",
    colour = "LIGHTCYAN",
    tile = "urand_spriggans_knife",
    tile_equipment = "spriggans_knife",
    type = "knife",
    flags = {
    },
    -- Spriggan's Knife properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        ev = 4,
        plus = 7,
        stealth = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
