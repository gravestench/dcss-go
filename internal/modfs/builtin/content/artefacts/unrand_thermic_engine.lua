-- Maxwell's thermic engine (artefact_ids.UNRAND_THERMIC_ENGINE) is a unique
-- artefact based on item_ids.WPN_DOUBLE_SWORD.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_THERMIC_ENGINE,
    name = "Maxwell's thermic engine",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DOUBLE_SWORD,
    fallback = "",
    brand = brands.FLAMING,
    fallback_brand = "",
    appearance = "",
    inscription = "freeze,",
    description = "It becomes more effective when it hits something. This effect fades\nover time.",
    brand_description =
        "It freezes those it strikes, dealing additional cold damage. It can\nalso slow down cold-blooded creatures" ..
        ".",
    colour = "ETC_VEHUMET",
    tile = "urand_thermic_engine",
    tile_equipment = "thermic_engine",
    type = "",
    flags = {
    },
    -- Maxwell's thermic engine properties are projected into equipment effects;
    -- avoid duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
