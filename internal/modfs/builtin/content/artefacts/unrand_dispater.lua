-- staff of Dispater (artefact_ids.UNRAND_DISPATER) is a unique artefact based
-- on item_ids.WPN_STAFF.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DISPATER,
    name = "staff of Dispater",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "golden staff",
    inscription = "",
    description =
        "It can be evoked to hurl damnation at the cost of health and magic,\nwith strength depending on Evocations" ..
        " skill.",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "spwpn_staff_of_dispater",
    tile_equipment = "dispater",
    type = "",
    flags = {
        "evil",
        "nogen",
    },
    -- staff of Dispater properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 4,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
