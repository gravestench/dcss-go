-- mut tentacle arms (MUT_TENTACLE_ARMS) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut tentacle arms descriptions are indexed by the player's effective
    -- mutation level.
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
