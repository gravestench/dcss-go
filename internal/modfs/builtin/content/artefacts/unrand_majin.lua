-- Majin-Bo (artefact_ids.UNRAND_MAJIN) is a unique artefact based on
-- item_ids.WPN_QUARTERSTAFF.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_MAJIN,
    name = "Majin-Bo",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_QUARTERSTAFF,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_LAJATANG,
    },
    brand = brands.VAMPIRISM,
    fallback_brand = "",
    appearance = "",
    inscription = "vamp,",
    description = "Its wielder's spells cost health as well as magical power.",
    brand_description =
        "It heals its wielder for a portion of the damage dealt\nwhen they wound a living foe with it or with a spe" ..
        "ll.",
    colour = "ETC_UNHOLY",
    tile = "spwpn_majin",
    tile_equipment = "majin",
    type = "",
    flags = {
        "skip_ego",
    },
    -- Majin-Bo properties are projected into equipment effects; avoid duplicating
    -- a wearer-only flag on the item entity.
    properties = {
        int = 6,
        mp = 6,
        plus = 6,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
