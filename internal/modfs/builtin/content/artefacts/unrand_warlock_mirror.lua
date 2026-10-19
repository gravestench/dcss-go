-- warlock's mirror (artefact_ids.UNRAND_WARLOCK_MIRROR) is a unique artefact
-- based on item_ids.ARM_BUCKLER.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_WARLOCK_MIRROR,
    name = "warlock's mirror",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BUCKLER,
    fallback = "",
    brand = armour_egos.REFLECTION,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description =
        "It can block and reflect piercing ranged attacks and magical attacks\nagainst the wielder's willpower.",
    brand_description = "",
    colour = "ETC_SILVER",
    tile = "urand_warlock",
    tile_equipment = "buckler_warlock",
    type = "",
    flags = {
    },
    -- warlock's mirror properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 3,
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
