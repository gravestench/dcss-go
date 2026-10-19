-- Source: traps.cc:_free_self_from_web and free_self_from_net.
local component = require("constants.component")
local ids = require("ids.traps")
local streams = require("constants.rng_streams")

local held = {}

-- Web hold is stored on the actor so movement can attempt escape later.
function held.catch_web(ctx, actor)
    if ctx:has(actor, component.TRAP_HELD) then
        return false
    end

    ctx:add(actor, component.TRAP_HELD, {
        kind_id = ids.TRAP_WEB,
        net_item_id = 0,
    })

    return true
end

-- Net hold keeps the item ID so escape can damage that exact projectile entity.
function held.catch_net(ctx, actor, net_item)
    if ctx:has(actor, component.TRAP_HELD) then
        return false
    end

    ctx:add(actor, component.TRAP_HELD, {
        kind_id = ids.TRAP_NET,
        net_item_id = ctx:id(net_item),
    })

    return true
end

-- A web struggle uses trap RNG and retains held state on a failed attempt.
local function escape_web(ctx, actor)
    if ctx:random(streams.TRAPS, 10) < 3 then
        ctx:emit("trap", "You struggle to detach yourself from the web.")

        return false
    end

    ctx:remove(actor, component.TRAP_HELD)
    ctx:emit("trap", "You disentangle yourself.")

    return true
end

-- Net struggles damage the actual projectile entity; a missing net would make saved held state inconsistent.
local function escape_net(ctx, actor, state)
    local net_item = ctx:entity(state.net_item_id)
    local durability = net_item and ctx:get(net_item, component.PROJECTILE_NET)

    if not durability then
        error("held actor has no trapping net")
    end

    local damage = 1 + ctx:random(streams.TRAPS, 4)

    durability.durability = durability.durability - damage

    if durability.durability < -7 then
        ctx:destroy(net_item)
        ctx:remove(actor, component.TRAP_HELD)
        ctx:emit("trap", "You rip the net and break free!")

        return true
    end

    ctx:set(net_item, component.PROJECTILE_NET, durability)
    ctx:emit("trap", "You struggle against the net.")

    return false
end

-- Webs and nets have different escape rules; route by saved restraint kind before clearing it.
-- Example: a web makes one trap-stream escape roll; a net instead loses 1..4 durability per attempt.
function held.escape(ctx, actor)
    local state = ctx:get(actor, component.TRAP_HELD)

    if not state then
        return true
    end

    if state.kind_id == ids.TRAP_WEB then
        return escape_web(ctx, actor)
    end

    if state.kind_id == ids.TRAP_NET then
        return escape_net(ctx, actor, state)
    end

    error("unknown trap restraint " .. state.kind_id)
end

-- Forced relocation detaches the actor. A net remains on its old floor cell.
function held.release(ctx, actor)
    local state = ctx:get(actor, component.TRAP_HELD)

    if not state then
        return
    end

    if state.kind_id == ids.TRAP_NET then
        local item = ctx:entity(state.net_item_id)

        if item then
            ctx:remove(item, component.PROJECTILE_NET)
        end
    end

    ctx:remove(actor, component.TRAP_HELD)
end

return held
