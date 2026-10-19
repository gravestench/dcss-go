-- ring of the Octopus King (artefact_ids.UNRAND_OCTOPUS_KING_RING) is a
-- unique artefact based on sentinels.RANDOM_RING.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local sentinels = require("constants.artefact_base_sentinels")

local definition = {
    id = artefact_ids.UNRAND_OCTOPUS_KING_RING,
    name = "ring of the Octopus King",
    class = classes.OBJ_JEWELLERY,
    kind_id = sentinels.RANDOM_RING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_WATER",
    tile = "urand_octoring",
    tile_equipment = "",
    type = "",
    flags = {
        "unided",
        "no_upgrade",
    },
    -- ring of the Octopus King properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        ac = 2,
        ev = 2,
        hp = 2,
        sh = 2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
