-- Source: item-use.cc:SCR_SILENCE calls cast_silence(30).
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")
local spells = require("ids.spells")
local statuses = require("policy.magic.effects.statuses.player")

local effect = {}
local SILENCE_POWER = 30

function effect.prepare()
    return nil
end

function effect.apply(ctx, player)
    statuses.cast(ctx, player, spells.SPELL_SILENCE, SILENCE_POWER)
end

scrolls.register(item_ids.SCR_SILENCE, effect)

return effect
