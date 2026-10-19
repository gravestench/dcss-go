-- morningstar \"Eos\ (artefact_ids.UNRAND_EOS) is a unique artefact based on
-- item_ids.WPN_MORNINGSTAR.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_EOS,
    name = "morningstar \"Eos\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_MORNINGSTAR,
    fallback = "",
    brand = brands.ELECTROCUTION,
    fallback_brand = "",
    appearance = "",
    inscription = "Halo",
    description =
        "It grants its wielder a halo, revealing invisible creatures and\nincreasing accuracy against all within it" ..
        " other than the wielder.",
    brand_description = "",
    colour = "ETC_JEWEL",
    tile = "urand_eos",
    tile_equipment = "eos",
    type = "",
    flags = {
        "elec",
    },
    -- morningstar \"Eos\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 10,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
