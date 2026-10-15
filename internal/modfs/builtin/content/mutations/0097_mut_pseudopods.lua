-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1300
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_PSEUDOPODS",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "pseudopods",
    description =
        "You are covered in pseudopods, allowing you to slap your foes when launching\nmelee" ..
        " attacks, but somewhat reducing the amount of protection provided by body\narmour." ..
        " This has no effect on protection provided by armour enchantments, nor\non the" ..
        " defensive benefits of training the Armour skill. Each level of this\nmutation makes" ..
        " your pseudopods larger and stronger.",
    have = {
        "Armour fits poorly on your pseudopods.",
        "Armour fits poorly on your large pseudopods.",
        "Armour fits poorly on your massive pseudopods.",
    },
    gain = {
        "Pseudopods emerge from your body.",
        "Your pseudopods grow in size.",
        "Your pseudopods grow in size.",
    },
    lose = {
        "Your pseudopods retract into your body.",
        "Your pseudopods become smaller.",
        "Your pseudopods become smaller.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
