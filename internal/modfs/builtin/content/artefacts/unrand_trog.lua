-- Wrath of Trog (artefact_ids.UNRAND_TROG) is a unique artefact based on
-- item_ids.WPN_BATTLEAXE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_TROG,
    name = "Wrath of Trog",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BATTLEAXE,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_EXECUTIONERS_AXE,
    },
    brand = brands.ANTIMAGIC,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description =
        "It causes slowness and exhaustion when equipped.\n+It extends the wielder's berserk rage when killing foes" ..
        ".",
    brand_description = "",
    colour = "ETC_BLOOD",
    tile = "spwpn_wrath_of_trog",
    tile_equipment = "axe_trog",
    type = "",
    flags = {
        "rampage",
    },
    -- Wrath of Trog properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        angry = 50,
        plus = 8,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
