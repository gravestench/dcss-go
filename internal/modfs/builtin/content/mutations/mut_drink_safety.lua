-- mut drink safety (MUT_DRINK_SAFETY) has up to 2 levels and selection weight
-- 7.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut drink safety descriptions are indexed by the player's effective
    -- mutation level.
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
