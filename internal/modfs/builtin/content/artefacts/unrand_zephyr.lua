-- longbow \"Zephyr\ (artefact_ids.UNRAND_ZEPHYR) is a unique artefact based
-- on item_ids.WPN_LONGBOW.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ZEPHYR,
    name = "longbow \"Zephyr\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LONGBOW,
    fallback = "",
    brand = brands.SPEED,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "urand_zephyr",
    tile_equipment = "zephyr",
    type = "",
    flags = {
        "seeinv",
    },
    -- longbow \"Zephyr\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        dex = 3,
        plus = 8,
    },
    -- The random mode admits Zephyr to unique.choose when its longbow base
    -- matches; generation history prevents an ordinary duplicate.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
