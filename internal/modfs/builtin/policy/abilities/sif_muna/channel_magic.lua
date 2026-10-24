-- Channel Magic converts a successful first-star invocation into a saved
-- player timer. The channel owner, not this ability, pays future MP.
local abilities = require("ids.abilities")
local channels = require("constants.message_channels")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local mutation_capabilities = require("constants.mutation_capabilities")
local mutation_effects = require("policy.mutations.effects.registry")
local registry = require("policy.abilities.registry")
local sif_channel = require("policy.religion.sif_muna.channel")

local channel_magic = {}

-- Source hides the MP power from HP-casting species, whose spell resource
-- cannot benefit from ordinary MP restoration.
function channel_magic.available(ctx, player)
    return costs.available(ctx, player, gods.SIF_MUNA, 1) and
        mutation_effects.sum(ctx, player,
            mutation_capabilities.HP_CASTING) == 0
end

-- This is a self-directed ability with no target or resource preflight.
function channel_magic.prepare()
    return nil
end

-- A failed invocation costs its action alone. Success extends the channel
-- and pays one ordinary generic two-point piety cost.
function channel_magic.resolve(ctx, player)
    if costs.failed(ctx, player, 60, 4, 25) then
        ctx:emit(channels.RELIGION, "You fail to use your ability.")

        return
    end

    sif_channel.start(ctx, player)
    costs.spend(ctx, player, 0, costs.piety_cost(ctx, 2))
end

registry.add(abilities.SIF_MUNA_CHANNEL_ENERGY, {
    name = "Channel Magic",
    available = channel_magic.available,
    prepare = channel_magic.prepare,
    resolve = channel_magic.resolve,
})

return channel_magic
