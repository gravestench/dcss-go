-- Source: item-use.cc:SCR_SILENCE calls cast_silence(30).
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")
local spells = require("ids.spells")
local statuses = require("policy.magic.effects.statuses.player")

local effect = {}
local SILENCE_POWER = 30

-- Silence has no target menu because its status always attaches to the reader.
function effect.prepare()
    return nil
end

-- Example: Silence begins a saved player aura that later cast preflight can inspect.
-- Apply fixed-power Silence through the shared status caster so later spells see its aura.
function effect.apply(ctx, player)
    statuses.cast(ctx, player, spells.SPELL_SILENCE, SILENCE_POWER)
end

scrolls.register(item_ids.SCR_SILENCE, effect)

return effect
