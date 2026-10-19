-- cloak of Starlight (artefact_ids.UNRAND_STARLIGHT) is a unique artefact
-- based on item_ids.ARM_CLOAK.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_STARLIGHT,
    name = "cloak of Starlight",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CLOAK,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Dazzle",
    description = "It may blind those who miss an attack against the wearer in melee\ncombat.",
    brand_description = "",
    colour = "ETC_ICE",
    tile = "urand_starlight",
    tile_equipment = "white",
    type = "",
    flags = {
    },
    -- cloak of Starlight properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        ev = 4,
        plus = 1,
        stealth = -2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
