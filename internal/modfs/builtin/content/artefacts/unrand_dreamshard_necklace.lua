-- dreamshard necklace (artefact_ids.UNRAND_DREAMSHARD_NECKLACE) is a unique
-- artefact based on item_ids.AMU_NOTHING.
-- Generation chooses the artefact once; equipment policy interprets its
-- properties while the item entity owns possession.

-- Source: crawl-ref/source/art-data.txt

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DREAMSHARD_NECKLACE,
    name = "dreamshard necklace",
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Dream",
    description =
        "It shatters if its wearer takes lethal or near-lethal damage,\npreventing the blow and releasing protectiv" ..
        "e dreams that heal and fight\nfor the wearer.",
    brand_description = "",
    colour = "ETC_SILVER",
    tile = "urand_dreamshard",
    tile_equipment = "",
    type = "",
    flags = {
        "drain",
        "special",
    },
    -- dreamshard necklace properties are projected into equipment effects; avoid
    -- duplicating a wearer-only flag on the item entity.
    properties = {
        value = 2000,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
