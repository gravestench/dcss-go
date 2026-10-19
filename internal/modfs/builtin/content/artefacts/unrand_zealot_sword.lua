-- zealot's sword (artefact_ids.UNRAND_ZEALOT_SWORD) is a unique artefact
-- based on item_ids.WPN_EUDEMON_BLADE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ZEALOT_SWORD,
    name = "zealot's sword",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_EUDEMON_BLADE,
    fallback = "",
    brand = brands.HOLY_WRATH,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "Whenever the wielder enters a berserk rage, their allies are\nberserked alongside them.",
    brand_description = "",
    colour = "ETC_HOLY",
    tile = "unrand_zealot_sword",
    tile_equipment = "zealot_sword",
    type = "",
    flags = {
    },
    -- zealot's sword properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        angry = 20,
        ev = 3,
        life = 1,
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
