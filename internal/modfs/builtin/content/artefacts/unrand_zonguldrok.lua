-- sword of Zonguldrok (artefact_ids.UNRAND_ZONGULDROK) is a unique artefact
-- based on item_ids.WPN_DOUBLE_SWORD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ZONGULDROK,
    name = "sword of Zonguldrok",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DOUBLE_SWORD,
    fallback = "",
    brand = brands.REAPING,
    fallback_brand = brands.PAIN,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_BONE",
    tile = "spwpn_sword_of_zonguldrok",
    tile_equipment = "zonguldrok",
    type = "",
    flags = {
        "evil",
    },
    -- sword of Zonguldrok properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 9,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
