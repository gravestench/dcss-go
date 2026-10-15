-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1342
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_POTION_HEAL",
    status = "active",
    weight = 3,
    max_level = 2,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no potion heal",
    description =
        "Your system is resistant to potable panaceas, reducing the effectiveness of all\nkinds" ..
        " of healing potions. The second level of this mutation completely blocks\npotion-based" ..
        " healing. (Aid from the god Gozag is unaffected.)",
    have = {
        "Potions are less effective at restoring your health.",
        "Potions cannot restore your health.",
        "",
    },
    gain = {
        "Your system partially rejects the healing effects of potions.",
        "Your system completely rejects the healing effects of potions.",
        "",
    },
    lose = {
        "Your system completely accepts the healing effects of potions.",
        "Your system partly accepts the healing effects of potions.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
