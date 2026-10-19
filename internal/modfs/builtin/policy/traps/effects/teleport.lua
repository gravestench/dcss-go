local player_teleport = require("policy.magic.player_teleport")
local catalog = require("policy.catalog")
local component = require("constants.component")
local net = require("policy.combat.net")
local streams = require("constants.rng_streams")
local monster_teleport = require("policy.magic.effects.zaps.teleport_other")
local held = require("policy.traps.held")

local effect = {}

function effect.trigger(ctx, _, actor)
    if actor == ctx:player() then
        ctx:emit("trap", "You enter a teleport trap!")
        player_teleport.now(ctx, actor)

        return
    end

    local state = ctx:get(actor, component.ACTOR)
    local position = ctx:get(actor, component.POSITION)

    if not state or not position then
        error("teleport trap actor has no position")
    end

    local definition = catalog.get("monsters", state.kind_id)

    if monster_teleport.no_tele(state, definition, ctx, actor) then
        return
    end

    -- Keep trap draws separate from spell draws. A random whole-level
    -- destination uses the same occupancy and habitat rules as Teleport Other.
    local width, height = ctx:level_size(position.level_id)
    local habitat = require("policy.combat.monster_habitat")

    for _ = 1, 1000 do
        local x = ctx:random(streams.TRAPS, width)
        local y = ctx:random(streams.TRAPS, height)

        if not ctx:actor_at(position.level_id, x, y) and
            habitat.at(ctx, actor, position.level_id, x, y) then
            net.release(ctx, actor)
            held.release(ctx, actor)
            ctx:move_actor(actor, position.level_id, x, y)
            ctx:emit("trap", "The " .. definition.name .. " disappears!")

            return
        end
    end
end

return effect
