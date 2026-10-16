local ids = require("ids.artefact_properties")
local kinds = require("constants.artefact_value_kinds")

-- Source: crawl-ref/source/artefact.cc:650-774. Array order matters:
-- source weighted selection iterates the property enum in this order.
local properties = {
    {
        id = ids.STRENGTH,
        weight = 100,
        good = kinds.STAT,
        bad = kinds.STAT,
        max = 7,
        increase = 1,
    },
    {
        id = ids.INTELLIGENCE,
        weight = 100,
        good = kinds.STAT,
        bad = kinds.STAT,
        max = 7,
        increase = 1,
    },
    {
        id = ids.DEXTERITY,
        weight = 100,
        good = kinds.STAT,
        bad = kinds.STAT,
        max = 7,
        increase = 1,
    },
    {
        id = ids.FIRE,
        weight = 60,
        good = kinds.RESISTANCE,
        bad = kinds.RESISTANCE,
        max = 2,
        increase = 4,
    },
    {
        id = ids.COLD,
        weight = 60,
        good = kinds.RESISTANCE,
        bad = kinds.RESISTANCE,
        max = 2,
        increase = 4,
    },
    {
        id = ids.ELECTRICITY,
        weight = 55,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.POISON,
        weight = 55,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.NEGATIVE_ENERGY,
        weight = 55,
        good = kinds.RESISTANCE,
        max = 2,
        increase = 4,
    },
    {
        id = ids.WILLPOWER,
        weight = 50,
        good = kinds.RESISTANCE,
        bad = kinds.RESISTANCE,
        max = 2,
        increase = 4,
    },
    {
        id = ids.SEE_INVISIBLE,
        weight = 30,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.INVISIBLE,
        weight = 15,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.FLY,
        weight = 15,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.BLINK,
        weight = 15,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.NOISE,
        weight = 30,
        bad = kinds.NOISE,
    },
    {
        id = ids.PREVENT_SPELLCASTING,
        weight = 25,
        bad = kinds.BOOLEAN,
    },
    {
        id = ids.PREVENT_TELEPORTATION,
        weight = 25,
        bad = kinds.BOOLEAN,
    },
    {
        id = ids.ANGRY,
        weight = 30,
        bad = kinds.ANGRY,
    },
    {
        id = ids.CONTAM,
        weight = 20,
        bad = kinds.BOOLEAN,
    },
    {
        id = ids.SLAYING,
        weight = 30,
        good = kinds.SLAYING,
        bad = kinds.SLAYING,
        max = 3,
        increase = 2,
    },
    {
        id = ids.STEALTH,
        weight = 40,
        good = kinds.RESISTANCE,
        bad = kinds.RESISTANCE,
    },
    {
        id = ids.MAGICAL_POWER,
        weight = 15,
        good = kinds.HPMP,
        bad = kinds.HPMP,
    },
    {
        id = ids.REGENERATION,
        weight = 35,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.RCORR,
        weight = 40,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.CORRODE,
        weight = 25,
        bad = kinds.BOOLEAN,
    },
    {
        id = ids.DRAIN,
        weight = 25,
        bad = kinds.BOOLEAN,
    },
    {
        id = ids.SLOW,
        weight = 25,
        bad = kinds.BOOLEAN,
    },
    {
        id = ids.FRAGILE,
        weight = 30,
        bad = kinds.BOOLEAN,
    },
    {
        id = ids.HARM,
        weight = 25,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.RAMPAGING,
        weight = 25,
        good = kinds.BOOLEAN,
    },
    {
        id = ids.ARCHMAGI,
        weight = 25,
        good = kinds.BOOLEAN,
    },
}

return properties
