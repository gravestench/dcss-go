-- Source: item-use.cc:SCR_FEAR passes power 1000 to mass_enchantment.
local item_ids = require("ids.items")
local mass = require("policy.magic.effects.statuses.mass_enchantment")
local scrolls = require("policy.scrolls")
local spells = require("ids.spells")

local effect = {}
local FEAR_POWER = 1000

function effect.prepare()
    return nil
end

function effect.apply(ctx, player)
    ctx:emit("read", "You assume a fearsome visage.")
    mass.cast(ctx, player, spells.SPELL_CAUSE_FEAR, FEAR_POWER)
end

scrolls.register(item_ids.SCR_FEAR, effect)

return effect
