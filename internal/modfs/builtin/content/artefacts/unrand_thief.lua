-- cloak of the Thief (artefact_ids.UNRAND_THIEF) is a unique artefact based
-- on item_ids.ARM_CLOAK.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_THIEF,
    name = "cloak of the Thief",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CLOAK,
    fallback = "",
    brand = "",
    fallback_brand = armour_egos.INVISIBILITY,
    appearance = "",
    inscription = "*Fog",
    description = "It may release a thick cloud of smoke when the wearer is hurt.",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_thief",
    tile_equipment = "black",
    type = "",
    flags = {
        "seeinv",
    },
    -- cloak of the Thief properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 2,
        slay = -2,
        stealth = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
