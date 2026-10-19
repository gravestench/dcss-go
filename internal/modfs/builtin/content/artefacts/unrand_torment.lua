-- sceptre of Torment (artefact_ids.UNRAND_TORMENT) is a unique artefact based
-- on item_ids.WPN_EVENINGSTAR.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_TORMENT,
    name = "sceptre of Torment",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_EVENINGSTAR,
    fallback = "",
    brand = brands.PAIN,
    fallback_brand = "",
    appearance = "",
    inscription = "torment",
    description = "",
    brand_description = "It occasionally torments all nearby living foes when it strikes in\ncombat.",
    colour = "ETC_GOLD",
    tile = "spwpn_sceptre_of_torment",
    tile_equipment = "sceptre_of_torment",
    type = "",
    flags = {
        "evil",
    },
    -- sceptre of Torment properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 7,
        value = 1200,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
