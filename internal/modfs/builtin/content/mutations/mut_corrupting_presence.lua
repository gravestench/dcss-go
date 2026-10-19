-- mut corrupting presence (MUT_CORRUPTING_PRESENCE) has up to 2 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut corrupting presence descriptions are indexed by the player's
    -- effective mutation level.
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
