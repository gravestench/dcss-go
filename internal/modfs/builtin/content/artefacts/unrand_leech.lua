-- demon blade \"Leech\ (artefact_ids.UNRAND_LEECH) is a unique artefact based
-- on item_ids.WPN_DEMON_BLADE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_LEECH,
    name = "demon blade \"Leech\"",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DEMON_BLADE,
    fallback = "",
    brand = brands.VAMPIRISM,
    fallback_brand = "",
    appearance = "",
    inscription = "vamp,",
    description = "",
    brand_description = "It heals its wielder for a portion of the damage dealt every time it\nstrikes a living foe.",
    colour = "ETC_DARK",
    tile = "urand_leech",
    tile_equipment = "leech",
    type = "",
    flags = {
        "drain",
        "harm",
        "skip_ego",
    },
    -- demon blade \"Leech\ properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        life = 1,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
