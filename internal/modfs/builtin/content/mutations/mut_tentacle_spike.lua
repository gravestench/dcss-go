-- mut tentacle spike (MUT_TENTACLE_SPIKE) has up to 3 levels and selection
-- weight 10.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TENTACLE_SPIKE",
    status = "active",
    weight = 10,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "tentacle spike",
    description =
        "You have a spiked tentacle, allowing you to pierce foes when launching melee\nattacks." ..
        " Each level of this mutation makes your spike sharper, longer, and\nstronger.",
    -- These mut tentacle spike descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "One of your tentacles bears a spike.",
        "One of your tentacles bears a nasty spike.",
        "One of your tentacles bears a large vicious spike.",
    },
    gain = {
        "One of your lower tentacles grows a sharp spike.",
        "Your tentacle spike grows bigger.",
        "Your tentacle spike grows even bigger.",
    },
    lose = {
        "Your tentacle spike disappears.",
        "Your tentacle spike becomes smaller.",
        "Your tentacle spike recedes somewhat.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
