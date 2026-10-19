-- sceptre of Asmodeus (artefact_ids.UNRAND_ASMODEUS) is a unique artefact
-- based on item_ids.WPN_STAFF.
-- Generation mode none excludes this authored unique from random selection.
-- Equipment reads its properties only if an item instance exists.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ASMODEUS,
    name = "sceptre of Asmodeus",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "ruby sceptre",
    inscription = "",
    description =
        "It can be evoked to summon fiery demons, with success rate depending\non Evocations skill. Those summoned " ..
        "this way will remain friendly only for a\nlimited time.",
    brand_description = "",
    colour = "ETC_BLOOD",
    tile = "spwpn_sceptre_of_asmodeus",
    tile_equipment = "asmodeus",
    type = "",
    flags = {
        "evil",
        "nogen",
    },
    -- sceptre of Asmodeus properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 7,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
