-- Makhleb's two active destruction powers each draw uniformly from five
-- source zaps. Keep the choice lists here so a mod can replace one policy
-- without duplicating zap names across its ability handlers.
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local destruction = {}

destruction.minor = {
    spells.SPELL_THROW_FLAME,
    spells.SPELL_PAIN,
    spells.SPELL_STONE_ARROW,
    spells.SPELL_SHOCK,
    zaps.ZAP_BREATHE_ACID,
}

destruction.major = {
    spells.SPELL_BOLT_OF_FIRE,
    spells.SPELL_LIGHTNING_BOLT,
    spells.SPELL_BOLT_OF_MAGMA,
    spells.SPELL_BOLT_OF_DRAINING,
    spells.SPELL_CORROSIVE_BOLT,
}

return destruction
