-- Mad Mage's Maulers (artefact_ids.UNRAND_POWER_GLOVES) is a unique artefact
-- based on item_ids.ARM_GLOVES.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_POWER_GLOVES,
    name = "Mad Mage's Maulers",
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_GLOVES,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Infuse+∞ RegenMP",
    description =
        "It empowers its wearer's blows with all of their magic.\n+It causes its wearer's magical reserves to regen" ..
        "erate more quickly.",
    brand_description = "",
    colour = "ETC_MAGIC",
    tile = "urand_power_gloves",
    tile_equipment = "glove_brown",
    type = "",
    flags = {
    },
    -- Mad Mage's Maulers properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        int = -3,
        plus = 3,
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
