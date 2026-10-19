-- frozen axe \"Frostbite\ (artefact_ids.UNRAND_FROSTBITE) is a unique
-- artefact based on item_ids.WPN_EXECUTIONERS_AXE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_FROSTBITE,
    name = "frozen axe \"Frostbite\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_EXECUTIONERS_AXE,
    fallback = "",
    brand = brands.FREEZING,
    fallback_brand = "",
    appearance = "",
    inscription = "freezing cloud,",
    description = "It grants immunity to clouds of freezing vapour.",
    brand_description =
        "It freezes those it strikes, dealing additional cold damage. It can\nalso slow down cold-blooded creatures" ..
        ".\n+\n+It occasionally leaves clouds of freezing vapour upon striking a foe.",
    colour = "ETC_ICE",
    tile = "urand_frostbite",
    tile_equipment = "frostbite",
    type = "",
    flags = {
        "skip_ego",
        "fly",
        "noises",
    },
    -- frozen axe \"Frostbite\ properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        cold = 1,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
