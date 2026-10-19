-- staff of Wucad Mu (artefact_ids.UNRAND_WUCAD_MU) is a unique artefact based
-- on item_ids.WPN_STAFF.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_WUCAD_MU,
    name = "staff of Wucad Mu",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_STAFF,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*channel",
    description =
        "It occasionally powers its wielder's spells, but with a chance of\ncausing confusion or draining the wield" ..
        "er's intelligence.\n+It becomes more likely to activate and less likely to backfire with increased\nEvocat" ..
        "ions skill.",
    brand_description = "",
    colour = "ETC_MAGIC",
    tile = "spwpn_wucad_mu",
    tile_equipment = "wucad_mu",
    type = "",
    flags = {
    },
    -- staff of Wucad Mu properties are projected into equipment effects; avoid
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
