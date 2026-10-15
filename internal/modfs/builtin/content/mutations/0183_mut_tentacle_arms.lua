-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2248
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TENTACLE_ARMS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "tentacles",
    description =
        "Your gelatinous body has eight tentacles that help you move around in shallow\nor deep" ..
        " water and can be used to constrict enemies while attacking them in\nmelee. Each" ..
        " tentacle can wear a ring, but you need four of them to move around,\nand either two" ..
        " or four tentacles to hold a weapon depending on its size, and\ntwo tentacles to hold" ..
        " a shield.\n\nA constriction attack has a 66% chance of automatically triggering on" ..
        " any\nmelee attack. When triggered, it will attempt to begin or renew constriction\nof" ..
        " a targeted enemy; the maximum number of enemies that can be constricted is" ..
        "\ndetermined by the number of free tentacles. Whether a constriction attempt\nsucceeds" ..
        " when triggered is determined primarily by Dexterity, Fighting skill,\nand any slaying" ..
        " bonuses.",
    have = {
        "You have tentacles for arms and can constrict enemies.",
        "",
        "",
    },
    gain = {
        "Your arms feel tentacular.",
        "",
        "",
    },
    lose = {
        "Your arms no longer feel tentacular.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
