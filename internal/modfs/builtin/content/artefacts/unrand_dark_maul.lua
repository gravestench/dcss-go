-- dark maul (artefact_ids.UNRAND_DARK_MAUL) is a unique artefact based on
-- item_ids.WPN_GREAT_MACE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_DARK_MAUL,
    name = "dark maul",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_MACE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_dark_maul",
    tile_equipment = "dark_maul",
    type = "maul",
    flags = {
    },
    -- dark maul properties are projected into equipment effects; avoid duplicating
    -- a wearer-only flag on the item entity.
    properties = {
        base_acc = 2,
        base_dam = 35,
        base_delay = 13,
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
