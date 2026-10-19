-- mut no artifice (MUT_NO_ARTIFICE) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_ARTIFICE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "inability to use devices",
    description =
        "You cannot use magical devices. This includes wands and most items evoked with" ..
        "\n<input>$cmd[CMD_EVOKE]</input>, excepting reaching weapons and ziggurat\nfigurines." ..
        " This also renders magical staves much less effective in melee.",
    -- These mut no artifice descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You cannot study or use magical devices.",
        "",
        "",
    },
    gain = {
        "You can no longer study or use magical devices.",
        "",
        "",
    },
    lose = {
        "You can once more study and use magical devices.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
