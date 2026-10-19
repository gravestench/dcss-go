-- sword of Power (artefact_ids.UNRAND_POWER) is a unique artefact based on
-- item_ids.WPN_GREAT_SWORD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_POWER,
    name = "sword of Power",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_SWORD,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description =
        "It occasionally discharges a powerful but inaccurate bolt of energy\nupon striking a foe, with increased c" ..
        "hance the greater the wielder's current\nhealth.",
    colour = "RED",
    tile = "spwpn_sword_of_power",
    tile_equipment = "sword_of_power",
    type = "",
    flags = {
    },
    -- sword of Power properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 5,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
