-- lajatang of Order (artefact_ids.UNRAND_ORDER) is a unique artefact based on
-- item_ids.WPN_LAJATANG.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ORDER,
    name = "lajatang of Order",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LAJATANG,
    fallback = "",
    brand = "",
    fallback_brand = brands.HOLY_WRATH,
    appearance = "",
    inscription = "silver,",
    description = "",
    brand_description =
        "It inflicts extra damage upon those it strikes, and deals\nsubstantially increased damage to chaotic, muta" ..
        "ted and magically transformed\nbeings.",
    colour = "ETC_SILVER",
    tile = "urand_order",
    tile_equipment = "order",
    type = "",
    flags = {
        "rMut",
    },
    -- lajatang of Order properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 7,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
