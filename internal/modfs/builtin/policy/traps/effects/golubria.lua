-- Source: traps.cc:_find_other_passage_side and trap_def::trigger.
local component = require("constants.component")
local ids = require("ids.traps")
local net = require("policy.combat.net")
local held = require("policy.traps.held")
local streams = require("constants.rng_streams")

local effect = {}

local function destination(ctx, trap, site)
    local open = {}
    local blocked = false

    for _, entity in ipairs(ctx:query({ component.WORLD_TRAP })) do
        local other = ctx:get(entity, component.WORLD_TRAP)

        if entity ~= trap and other.kind_id == ids.TRAP_GOLUBRIA and
            other.level_id == site.level_id then
            if ctx:actor_at(other.level_id, other.x, other.y) then
                blocked = true
            else
                open[#open + 1] = other
            end
        end
    end

    if #open == 0 then
        return nil, blocked
    end

    return open[ctx:random(streams.TRAPS, #open) + 1], false
end

function effect.trigger(ctx, trap, actor, site)
    local to, blocked = destination(ctx, trap, site)

    if not to then
        if actor == ctx:player() then
            local reason = blocked and "seems to be blocked by something" or
                "doesn't lead anywhere"

            ctx:emit("trap", "This passage " .. reason .. "!")
        end

        return false
    end

    local position = ctx:get(actor, component.POSITION)

    net.release(ctx, actor)
    held.release(ctx, actor)

    ctx:move_actor(actor, position.level_id, to.x, to.y)

    if actor == ctx:player() then
        ctx:emit("trap", "You enter the passage of Golubria.")
    end

    return true
end

return effect
