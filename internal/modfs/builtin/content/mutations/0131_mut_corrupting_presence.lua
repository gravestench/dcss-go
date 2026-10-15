-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1764
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CORRUPTING_PRESENCE",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "corrupting presence",
    description =
        "When you injure a foe, your presence may intensify the damage, corroding their" ..
        "\nweapons and defenses. The second level of this mutation makes matters even\nworse," ..
        " adding a chance that your wretched victims may become mutated and\ndeformed.",
    have = {
        "Your presence sometimes corrodes those you injure.",
        "Your presence sometimes corrodes or deforms those you injure.",
        "",
    },
    gain = {
        "You feel corrupt.",
        "Your corrupting presence intensifies.",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
