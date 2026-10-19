-- Elemental Staff (artefact_ids.UNRAND_ELEMENTAL_STAFF) is a unique artefact
-- based on item_ids.WPN_STAFF.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ELEMENTAL_STAFF,
    name = "Elemental Staff",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_LAJATANG,
    },
    brand = "",
    fallback_brand = brands.FREEZING,
    appearance = "",
    inscription = "",
    description = "It enhances your fire, ice, earth and air magic.",
    brand_description =
        "If the wielder is skilled in Evocations, they can discharge powerful\nblasts of elemental energy when stri" ..
        "king with it.",
    colour = "DARKGREY",
    tile = "urand_elemental",
    tile_equipment = "elemental_staff",
    type = "",
    flags = {
        "elec",
    },
    -- Elemental Staff properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        ac = 5,
        cold = 2,
        fire = 2,
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
