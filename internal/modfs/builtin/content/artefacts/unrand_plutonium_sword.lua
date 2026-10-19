-- plutonium sword (artefact_ids.UNRAND_PLUTONIUM_SWORD) is a unique artefact
-- based on item_ids.WPN_TRIPLE_SWORD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_PLUTONIUM_SWORD,
    name = "plutonium sword",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_TRIPLE_SWORD,
    fallback = "",
    brand = "",
    fallback_brand = brands.CHAOS,
    appearance = "",
    inscription = "",
    description = "",
    brand_description =
        "It occasionally inflicts wild transmutation effects on those it\nstrikes, inflicting malmutation or extra " ..
        "damage, or polymorphing them into a\nnew form.",
    colour = "ETC_MUTAGENIC",
    tile = "urand_plutonium",
    tile_equipment = "plutonium_sword",
    type = "",
    flags = {
        "mutate",
        "chaotic",
    },
    -- plutonium sword properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 11,
        stealth = -1,
        value = 1000,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
