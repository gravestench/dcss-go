-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1639
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_IGNITE_BLOOD",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "ignite blood",
    description =
        "Whenever you see blood spilled (yours or others'), it may ignite, bursting into\na" ..
        " cloud of flame. Each level of this mutation makes this more likely.\n# XXX: also" ..
        " mention that this makes people more likely to bleed?",
    have = {
        "Your demonic aura sometimes causes spilled blood to erupt in flames.",
        "Your demonic aura often causes spilled blood to erupt in flames.",
        "Your demonic aura causes all spilled blood to erupt in flames.",
    },
    gain = {
        "Your blood heats up.",
        "Your blood runs red-hot!",
        "Your blood burns even hotter!",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
