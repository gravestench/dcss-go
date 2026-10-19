-- Singing Sword (artefact_ids.UNRAND_SINGING_SWORD) is a unique artefact
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
    id = artefact_ids.UNRAND_SINGING_SWORD,
    name = "Singing Sword",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DOUBLE_SWORD,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "sonic wave",
    description = "",
    brand_description =
        "It radiates damaging sonic waves as it strikes, especially in combat\ninvolving dangerous or numerous foes" ..
        ".",
    colour = "ETC_GOLD",
    tile = "spwpn_singing_sword",
    tile_equipment = "singing_sword",
    type = "",
    flags = {
    },
    -- Singing Sword properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 7,
        value = 1000,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
