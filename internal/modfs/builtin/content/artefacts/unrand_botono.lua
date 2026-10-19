-- spear of the Botono (artefact_ids.UNRAND_BOTONO) is a unique artefact based
-- on item_ids.WPN_SPEAR.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_BOTONO,
    name = "spear of the Botono",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SPEAR,
    fallback = "",
    brand = brands.REAPING,
    fallback_brand = brands.PAIN,
    appearance = "",
    inscription = "Hex",
    description = "",
    brand_description = "",
    colour = "ETC_UNHOLY",
    tile = "urand_botono",
    tile_equipment = "botono",
    type = "",
    flags = {
        "poison",
        "nogen",
    },
    -- spear of the Botono properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        hp = -6,
        life = 1,
        plus = 6,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
