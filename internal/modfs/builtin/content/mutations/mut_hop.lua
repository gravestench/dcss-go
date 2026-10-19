-- mut hop (MUT_HOP) has up to 2 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HOP",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "strong legs",
    description =
        "You have big, strong legs, allowing you to hop about with" ..
        "\n<input>$cmd[CMD_USE_ABILITY]</input>, though you can't perfectly aim where you" ..
        "\nland. The second level of this mutation allows you to hop farther. Each time\nyou" ..
        " hop, you need to rest for a bit before you can hop again.",
    -- These mut hop descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You can hop short distances.",
        "You can hop long distances.",
        "",
    },
    gain = {
        "",
        "Your legs feel stronger.",
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
