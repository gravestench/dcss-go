-- mut pseudopods (MUT_PSEUDOPODS) has up to 3 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut pseudopods descriptions are indexed by the player's effective
    -- mutation level.
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
