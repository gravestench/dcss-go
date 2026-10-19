-- mut subdued magic (MUT_SUBDUED_MAGIC) has up to 3 levels and selection
-- weight 6.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SUBDUED_MAGIC",
    status = "active",
    weight = 6,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "subdued magic",
    description =
        "Your spells are slightly easier to cast (reduced miscast chance and severity),\nbut" ..
        " less powerful. Each level of this mutation increases both effects further.",
    -- These mut subdued magic descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your spells are a little easier to cast, but a little less powerful.",
        "Your spells are easier to cast, but less powerful.",
        "Your spells are much easier to cast, but much less powerful.",
    },
    gain = {
        "Your connection to magic feels subdued.",
        "Your connection to magic feels more subdued.",
        "Your connection to magic feels nearly dormant.",
    },
    lose = {
        "Your magic regains its normal vibrancy.",
        "Your connection to magic feels less subdued.",
        "Your connection to magic feels less subdued.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
