-- mut demonic magic (MUT_DEMONIC_MAGIC) has up to 3 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEMONIC_MAGIC",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "demonic magic",
    description =
        "When you cast spells, there's a chance that adjacent monsters will be\nparalysed. This" ..
        " effect is more powerful when casting higher-level spells, but\nmonsters with greater" ..
        " Willpower can resist it. Each level of this mutation\nallows more distant monsters to" ..
        " be affected. The third level of this mutation\nalso allows you to paralyse monsters" ..
        " in the same way while zapping wands.",
    -- These mut demonic magic descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Spells you cast may paralyse adjacent enemies.",
        "Spells you cast may paralyse nearby enemies.",
        "Spells you cast and wands you use may paralyse nearby enemies.",
    },
    gain = {
        "A menacing aura infuses your magic.",
        "Your magic grows more menacing.",
        "Your wands become infused with your menacing aura.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
