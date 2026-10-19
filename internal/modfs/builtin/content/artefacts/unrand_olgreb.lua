-- staff of Olgreb (artefact_ids.UNRAND_OLGREB) is a unique artefact based on
-- item_ids.WPN_STAFF.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_OLGREB,
    name = "staff of Olgreb",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "rPois∞",
    description =
        "It enhances your poison magic.\n+It grants immunity to poison.\n+It can be activated via the 'a'bility men" ..
        "u to radiate toxic energy, with\neffectiveness depending on Evocations skill.",
    brand_description =
        "If the wielder is skilled in Evocations, they can envenom those struck\nby it, dealing poison damage which" ..
        " bypasses armour.",
    colour = "ETC_POISON",
    tile = "spwpn_staff_of_olgreb",
    tile_equipment = "olgreb",
    type = "",
    flags = {
    },
    -- staff of Olgreb properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 9,
        value = 1000,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
