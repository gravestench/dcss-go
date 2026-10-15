-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1851
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DRINK_SAFETY",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "inability to drink after injury",
    description =
        "When you are harmed, there is a chance that you will become temporarily unable\nto" ..
        " drink potions. The greater the mutation level, damage done and the closer\nyou are to" ..
        " death, the greater the odds.",
    have = {
        "You occasionally lose the ability to drink potions when taking damage.",
        "You sometimes lose the ability to drink potions when taking damage.",
        "",
    },
    gain = {
        "You occasionally lose the ability to drink potions when taking damage.",
        "You lose the ability to drink potions when taking damage more often.",
        "",
    },
    lose = {
        "You no longer become unable to drink potions after taking damage.",
        "You lose the ability to drink potions when taking damage less often.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
