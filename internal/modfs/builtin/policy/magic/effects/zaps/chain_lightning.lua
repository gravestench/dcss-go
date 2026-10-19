-- Player Chain Lightning uses the same jump and thunder contact rule as
-- monster casts. Player zap dice divide 2*power among three dice before
-- each jump wave, while the monster zap keeps its separate source formula.
-- Source: spl-damage.cc:cast_chain_lightning and zap-data.h.
local area = require("policy.combat.monster_area.chain_lightning")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local registry = require("policy.magic.effects.registry")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local chain_lightning = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CHAIN_LIGHTNING)

-- The spell selects its nearest live body at cast time. A return to the
-- caster on a later jump is possible and uses the source's one-sixth dice.
function chain_lightning.resolve(ctx, player, _, _, power)
    local struck = area.resolve(ctx, player, power, profile,
        streams.SPELL, "Lightning arcs from your hands!")

    if not struck then
        ctx:emit(channels.SPELL, "Nothing happens.")
    end
end

registry.add(spells.SPELL_CHAIN_LIGHTNING, chain_lightning)

return chain_lightning
