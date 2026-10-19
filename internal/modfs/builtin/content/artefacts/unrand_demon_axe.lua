-- obsidian axe (artefact_ids.UNRAND_DEMON_AXE) is a unique artefact based on
-- item_ids.WPN_BROAD_AXE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_DEMON_AXE,
    name = "obsidian axe",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_BROAD_AXE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = brands.PAIN,
    appearance = "",
    inscription = "Mesm",
    description =
        "Its wielder is mesmerised by any visible foes.\n+It cannot be unequipped while any foes are visible.",
    brand_description = "It occasionally summons demons to assist the wielder when it strikes\nin combat.",
    colour = "ETC_UNHOLY",
    tile = "spwpn_demon_axe",
    tile_equipment = "demon_axe",
    type = "",
    flags = {
        "evil",
        "seeinv",
        "fly",
        "drain",
    },
    -- obsidian axe properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 14,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
