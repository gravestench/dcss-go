-- mut no potion heal (MUT_NO_POTION_HEAL) has up to 2 levels and selection
-- weight 3.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_POTION_HEAL",
    status = "active",
    weight = 3,
    max_level = 2,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no potion heal",
    description =
        "Your system is resistant to potable panaceas, reducing the effectiveness of all\nkinds" ..
        " of healing potions. The second level of this mutation completely blocks\npotion-based" ..
        " healing. (Aid from the god Gozag is unaffected.)",
    -- These mut no potion heal descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Potions are less effective at restoring your health.",
        "Potions cannot restore your health.",
        "",
    },
    gain = {
        "Your system partially rejects the healing effects of potions.",
        "Your system completely rejects the healing effects of potions.",
        "",
    },
    lose = {
        "Your system completely accepts the healing effects of potions.",
        "Your system partly accepts the healing effects of potions.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
