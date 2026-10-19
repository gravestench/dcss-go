-- Monster experience receives a danger adjustment from these spell classifications.

-- Source: mon-util.cc:exper_value. Dangerous spell slots add difficulty.
local spells = require("ids.spells")

local weights = {
    [spells.SPELL_PARALYSE] = 25,
    [spells.SPELL_SMITING] = 25,
    [spells.SPELL_SUMMON_EYEBALLS] = 25,
    [spells.SPELL_CALL_DOWN_DAMNATION] = 25,
    [spells.SPELL_HURL_DAMNATION] = 25,
    [spells.SPELL_SYMBOL_OF_TORMENT] = 25,
    [spells.SPELL_GLACIATE] = 25,
    [spells.SPELL_FIRE_STORM] = 25,
    [spells.SPELL_SHATTER] = 25,
    [spells.SPELL_CHAIN_LIGHTNING] = 25,
    [spells.SPELL_POLAR_VORTEX] = 25,
    [spells.SPELL_LEGENDARY_DESTRUCTION] = 25,
    [spells.SPELL_SUMMON_ILLUSION] = 25,
    [spells.SPELL_SPELLFORGED_SERVITOR] = 25,
    [spells.SPELL_CONJURE_LIVING_SPELLS] = 25,

    [spells.SPELL_SUMMON_GREATER_DEMON] = 20,
    [spells.SPELL_HASTE] = 20,
    [spells.SPELL_BLINK_RANGE] = 20,
    [spells.SPELL_PETRIFY] = 20,

    [spells.SPELL_LIGHTNING_BOLT] = 10,
    [spells.SPELL_STICKY_FLAME_RANGE] = 10,
    [spells.SPELL_MINDBURST] = 10,
    [spells.SPELL_BANISHMENT] = 10,
    [spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR] = 10,
    [spells.SPELL_IRON_SHOT] = 10,
    [spells.SPELL_IOOD] = 10,
    [spells.SPELL_FIREBALL] = 10,
    [spells.SPELL_AGONY_RANGE] = 10,
    [spells.SPELL_LRD] = 10,
    [spells.SPELL_DIG] = 10,
    [spells.SPELL_FAKE_MARA_SUMMON] = 10,

    [spells.SPELL_HAUNT] = 7,
    [spells.SPELL_SUMMON_DRAGON] = 7,
    [spells.SPELL_SUMMON_HORRIBLE_THINGS] = 7,
    [spells.SPELL_PLANEREND] = 7,
    [spells.SPELL_SUMMON_EMPEROR_SCORPIONS] = 7,
}

return weights
