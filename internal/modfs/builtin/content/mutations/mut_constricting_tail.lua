-- mut constricting tail (MUT_CONSTRICTING_TAIL) has up to 2 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CONSTRICTING_TAIL",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "naga tail",
    description =
        "You have a long, snake-like tail in place of feet. The second level of this\nmutation" ..
        " allows you to constrict foes with your tail when attacking in melee.\nYour tail can" ..
        " constrict only one enemy at a time, and every attack at this\nmutation level will" ..
        " begin or renew a constriction attempt. The chances of\nsucceeding are determined" ..
        " primarily by Dexterity, Fighting skill, and any\nslaying bonuses.",
    -- These mut constricting tail descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You have a snake-like lower body.",
        "You can use your snake-like lower body to constrict enemies.",
        "",
    },
    gain = {
        "Your lower body turns into a snake tail.",
        "Your tail grows strong enough to constrict your enemies.",
        "",
    },
    lose = {
        "Your lower body returns to normal.",
        "Your snake tail weakens and can no longer constrict your enemies.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
