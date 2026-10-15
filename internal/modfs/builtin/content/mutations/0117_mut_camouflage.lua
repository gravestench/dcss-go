-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1623
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CAMOUFLAGE",
    status = "active",
    weight = 1,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "camouflage",
    description =
        "Your skin changes colour to match your surroundings. Each level of this\nmutation" ..
        " provides Stealth+.",
    have = {
        "Your skin changes colour to match your surroundings (Stealth+).",
        "Your skin blends seamlessly with your surroundings (Stealth++).",
        "Your skin perfectly mimics your surroundings (Stealth+++).",
    },
    gain = {
        "Your skin functions as natural camouflage.",
        "Your natural camouflage becomes more effective.",
        "Your natural camouflage becomes more effective.",
    },
    lose = {
        "Your skin no longer functions as natural camouflage.",
        "Your natural camouflage becomes less effective.",
        "Your natural camouflage becomes less effective.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
