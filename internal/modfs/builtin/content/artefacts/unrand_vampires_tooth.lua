-- Vampire's Tooth (artefact_ids.UNRAND_VAMPIRES_TOOTH) is a unique artefact
-- based on item_ids.WPN_QUICK_BLADE.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_VAMPIRES_TOOTH,
    name = "Vampire's Tooth",
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_QUICK_BLADE,
    fallback = "",
    brand = brands.VAMPIRISM,
    fallback_brand = brands.VAMPIRISM,
    appearance = "",
    inscription = "vamp",
    description = "",
    brand_description =
        "It occasionally heals its wielder for the full amount of damage dealt\nwhen it wounds a living foe.",
    colour = "ETC_BONE",
    tile = "spwpn_vampires_tooth",
    tile_equipment = "vampires_tooth",
    type = "",
    flags = {
        "skip_ego",
    },
    -- Vampire's Tooth properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        plus = 8,
        value = 600,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
