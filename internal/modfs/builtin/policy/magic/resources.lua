local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")

local resources = {}

local function state(ctx, player)
    local health = ctx:get(player, "core.health")
    local magic = ctx:get(player, "core.magic")

    if not health or not magic then
        error("player lacks spell resource state")
    end

    local from_hp = mutation_effects.sum(ctx, player,
        mutation_capabilities.HP_CASTING) > 0

    return health, magic, from_hp
end

-- Source: spl-util.cc:casting_uselessness_reason and player.cc:pay_mp.
-- Djinni's spell cost is paid from HP and must leave at least one HP.
function resources.cannot_pay(ctx, player, cost)
    local health, magic, from_hp = state(ctx, player)

    if from_hp then
        if health.current <= cost then
            return "You don't have enough health to cast this spell."
        end
    elseif magic.current < cost then
        return "You don't have enough magic to cast this spell."
    end

    return nil
end

function resources.pay(ctx, player, cost)
    local rejection = resources.cannot_pay(ctx, player, cost)

    if rejection then
        error(rejection)
    end

    local health, magic, from_hp = state(ctx, player)

    if from_hp then
        health.current = health.current - cost
        ctx:set(player, "core.health", health)
    else
        magic.current = magic.current - cost
        ctx:set(player, "core.magic", magic)
    end
end

function resources.refund(ctx, player, cost)
    local health, magic, from_hp = state(ctx, player)

    if from_hp then
        health.current = math.min(health.max, health.current + cost)
        ctx:set(player, "core.health", health)
    else
        magic.current = math.min(magic.max, magic.current + cost)
        ctx:set(player, "core.magic", magic)
    end
end

return resources
