local registry = require("policy.magic.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")

local blink = {}

-- Blink uses Chebyshev distance because a diagonal step counts as one nearby cell.
local function distance(x, y)
    return math.max(math.abs(x), math.abs(y))
end

-- Source: teleport.cc:random_near_space. The first pass excludes adjacent
-- cells; a second independent pass permits them if no distant cell was found.
local function destination(ctx, position, allow_adjacent)
    local tried = {}

    for _ = 1, 150 do
        local dx = ctx:random("spell", 13) - 6
        local dy = ctx:random("spell", 13) - 6
        local index = (dx + 6) * 13 + dy + 6

        if not tried[index] then
            tried[index] = true

            local x = position.x + dx
            local y = position.y + dy

            if (allow_adjacent or distance(dx, dy) > 1) and
                ctx:walkable(position.level_id, x, y) and
                not ctx:actor_at(position.level_id, x, y) and
                ctx:visible(position.level_id, position.x, position.y,
                    7, x, y) then
                return x, y
            end
        end
    end

    return nil, nil
end

-- Round a fractional duration with the spell stream to preserve its expected value.
local function random_divide(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Example: An active blink cooldown returns an instability error before Blink chooses a destination.
-- Active blink cooldown rejects the cast before it spends MP or chooses a destination.
function blink.prepare(ctx, player)
    if statuses.blink_cooldown(ctx, player) > 0 then
        return "You are still too unstable to blink."
    end

    return nil
end

-- Try distant cells first, then nearby cells; failed searches leave the actor in place.
function blink.resolve(ctx, player, _, _, power)
    local position = ctx:get(player, "core.position")
    local x, y = destination(ctx, position, false)

    if not x then
        x, y = destination(ctx, position, true)
    end

    if x and not ctx:has(player, "core.constricted") then
        ctx:move_actor(player, position.level_id, x, y)
        ctx:emit("spell", "You blink.")
    elseif x then
        ctx:emit("spell", "You cannot escape your constriction!")
    else
        ctx:emit("spell", "You feel jittery for a moment.")
    end

    -- Source: spl-transloc.cc:cast_blink. Duration helpers store aut.
    local cooldown = random_divide(ctx, math.max(0, 50 - power), 10)

    if cooldown > 0 then
        local turns = 1 + ctx:random("spell", 2) + cooldown
        local remaining = statuses.blink_cooldown(ctx, player)

        statuses.set_blink_cooldown(ctx, player, remaining + turns * 10)
    end
end

registry.add("SPELL_BLINK", blink)
