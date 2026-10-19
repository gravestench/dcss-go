-- mut read safety (MUT_READ_SAFETY) has up to 2 levels and selection weight
-- 7.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_READ_SAFETY",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "bad",
        "xom",
    },
    form_based = false,
    short_description = "inability to read after injury",
    description =
        "When you are harmed, there is a chance that you will become temporarily unable\nto" ..
        " read. The greater the mutation level, damage done and the closer you are to\ndeath," ..
        " the greater the odds.",
    -- These mut read safety descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You occasionally lose the ability to read scrolls when taking damage.",
        "You sometimes lose the ability to read scrolls when taking damage.",
        "",
    },
    gain = {
        "You occasionally lose the ability to read scrolls when taking damage.",
        "You lose the ability to read scrolls when taking damage more often.",
        "",
    },
    lose = {
        "You no longer become unable to read scrolls after taking damage.",
        "You lose the ability to read scrolls when taking damage less often.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
