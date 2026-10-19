-- mut eyeballs (MUT_EYEBALLS) has up to 3 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_EYEBALLS",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "eyeballs",
    description =
        "Golden eyeballs sprout from your flesh like mushrooms, confusing your foes.\nEach" ..
        " level of this mutation improves your accuracy with weapons, unarmed\nattacks," ..
        " auxiliary attacks, and spells. The third level of this mutation also\nallows you to" ..
        " see invisible foes.",
    -- These mut eyeballs descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your body has grown eyes which may confuse attackers. (Acc +3)",
        "Your body has grown many eyes which may confuse attackers. (Acc +5)",
        "Your body is covered in eyes which may confuse attackers. (Acc +7, SInv)",
    },
    gain = {
        "Eyeballs grow over part of your body.",
        "Eyeballs cover a large portion of your body.",
        "Eyeballs cover you completely.",
    },
    lose = {
        "The eyeballs on your body disappear.",
        "The eyeballs on your body recede somewhat.",
        "The eyeballs on your body recede somewhat.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
