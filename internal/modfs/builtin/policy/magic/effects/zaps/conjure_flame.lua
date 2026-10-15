local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local cloud = require("policy.magic.effects.zaps.cloud")
local registry = require("policy.magic.effects.registry")

local conjure_flame = {}

local function duration(ctx, power)
    local capped = math.min(power, 100)
    local first = math.floor(ctx:random("spell", capped) / 2)
    local second = math.floor(ctx:random("spell", capped) / 2)

    return math.min(5 + first + second, 23) * 10
end

function conjure_flame.prepare(ctx, player)
    local position = ctx:get(player, component.POSITION)
    local entity = cloud.at(ctx, position.level_id, position.x, position.y)

    if entity then
        local state = ctx:get(entity, component.CLOUD)

        if state.kind_id ~= zap_ids.cloud.FIRE and
            state.kind_id ~= zap_ids.cloud.EMBERS then
            return "There's already a cloud here!"
        end
    end
end

function conjure_flame.resolve(ctx, player, _, _, power)
    local position = ctx:get(player, component.POSITION)
    local entity = cloud.at(ctx, position.level_id, position.x, position.y)

    if entity then
        local state = ctx:get(entity, component.CLOUD)

        if state.kind_id == zap_ids.cloud.FIRE then
            -- spl-clouds.cc:conjure_flame adds 5 decay units per extra turn.
            local extra = 2 + math.min(math.floor(
                ctx:random("spell", math.min(power, 100)) / 2), 20)

            state.expires_aut = state.expires_aut + extra * 5
            state.owner = player
            ctx:set(entity, component.CLOUD, state)
            ctx:emit("spell", "The fire blazes with new energy!")
            return
        end

        if state.kind_id == zap_ids.cloud.EMBERS then
            ctx:remove(entity, zap_ids.component.CONJURE_FLAME)
            state.kind_id = zap_ids.cloud.FIRE
            state.expires_aut = ctx:aut() + duration(ctx, power)
            ctx:set(entity, component.CLOUD, state)
            ctx:emit("spell", "The fire ignites!")
            return
        end

        error("Conjure Flame passed preparation with an incompatible cloud")
    end

    local ember = cloud.place(ctx, zap_ids.cloud.EMBERS, player,
        position.level_id, position.x, position.y, 11)

    if not ember then
        error("Conjure Flame could not place prepared embers")
    end

    ctx:add(ember, zap_ids.component.CONJURE_FLAME, {
        fire_duration_aut = duration(ctx, power),
    })
    ctx:emit("spell", "The fire begins to smoulder!")
end

registry.add(spells.SPELL_CONJURE_FLAME, conjure_flame)

return conjure_flame
