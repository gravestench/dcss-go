-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1789
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_WEAKNESS_STINGER",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "weakness stinger",
    description =
        "You have a thin, red tail, allowing you to tail-slap foes when launching melee" ..
        "\nattacks. Each level of this mutation increases your tail's strength as it turns" ..
        "\ninto a sharp stinger. The third level of this mutation causes the stinger to" ..
        "\ninflict brief weakness on those unfortunate enough to be struck by it.",
    have = {
        "You have a small tail.",
        "You have a tail ending in a sharp stinger.",
        "You have a sharp stinger which inflicts weakening toxins.",
    },
    gain = {
        "You grow a small tail.",
        "Your tail grows a sharp stinger.",
        "Your stinger grows larger and begins to produce weakening toxins.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
