-- Theory of operation: one saved player component owns Okawaru's two
-- temporary combat boons. Every effective-skill and attack-timing reader
-- asks this owner, so departure, penance, and ordinary expiry agree.
local component = require("constants.component")
local gods = require("constants.gods")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local okawaru = require("constants.okawaru")

local status = {}

local fields = {
    heroism = "heroism_aut",
    finesse = "finesse_aut",
}

local endings = {
    heroism = "You feel like a meek peon again.",
    finesse = "Your hands slow down.",
}
local order = { "heroism", "finesse" }

-- Check a named source boon by its remaining time, not by component
-- presence; the second boon can outlast the first in the same record.
function status.active(ctx, player, kind)
    local field = fields[kind]

    if not field then
        error("unknown Okawaru status " .. tostring(kind))
    end

    local state = ctx:get(player, component.RELIGION_OKAWARU_STATUS)

    return state ~= nil and state[field] > 0
end

-- Source random2avg(n,2) draws random2(n), then random2(n+1), and
-- truncates their average. Extend only the selected clock to 100 turns.
function status.invoke(ctx, player, kind)
    local field = fields[kind]

    if not field then
        error("unknown Okawaru status " .. tostring(kind))
    end

    -- Skill power is needed only when invoking, after the form and rage
    -- modules have finished loading; eager loading forms a Lua cycle.
    local magic_power = require("policy.magic.power")
    local power = magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, 6)
    local first = power > 0 and
        ctx:random(streams.RELIGION, power) or 0
    local second = ctx:random(streams.RELIGION, power + 1)
    local turns = okawaru.STATUS_BASE_TURNS +
        math.floor((first + second) / 2)
    local state = ctx:get(player, component.RELIGION_OKAWARU_STATUS) or {
        heroism_aut = 0,
        finesse_aut = 0,
    }
    local renewed = state[field] > 0

    state[field] = math.min(okawaru.STATUS_CAP_AUT,
        state[field] + turns * 10)

    if ctx:has(player, component.RELIGION_OKAWARU_STATUS) then
        ctx:set(player, component.RELIGION_OKAWARU_STATUS, state)
    else
        ctx:add(player, component.RELIGION_OKAWARU_STATUS, state)
    end

    if kind == "heroism" then
        ctx:emit("duration", renewed and
            "You feel more confident with your borrowed prowess." or
            "You gain the combat prowess of a mighty hero.")
    else
        ctx:emit("duration", renewed and
            "Your hands get new energy." or
            "You can now deal lightning-fast blows.")
    end
end

-- Removing one boon leaves the other clock intact. Berserk uses this to
-- end only Finesse, while natural expiry and penance use the same message.
function status.remove(ctx, player, kind, message)
    local field = fields[kind]
    local state = ctx:get(player, component.RELIGION_OKAWARU_STATUS)

    if not field or not state or state[field] <= 0 then
        return false
    end

    state[field] = 0

    if state.heroism_aut == 0 and state.finesse_aut == 0 then
        ctx:remove(player, component.RELIGION_OKAWARU_STATUS)
    else
        ctx:set(player, component.RELIGION_OKAWARU_STATUS, state)
    end

    ctx:emit("duration", message or endings[kind])

    return true
end

-- Patron departure and penance revoke both temporary grants immediately.
function status.clear(ctx, player)
    status.remove(ctx, player, "heroism")
    status.remove(ctx, player, "finesse")
end

-- Age both source clocks by elapsed player aut; a long action may end
-- both at once without emitting duplicate expiration messages.
function status.tick(ctx, player, aut)
    local state = ctx:get(player, component.RELIGION_OKAWARU_STATUS)

    if not state or aut <= 0 then
        return
    end

    for _, kind in ipairs(order) do
        local field = fields[kind]
        if state[field] > 0 then
            state[field] = math.max(0, state[field] - aut)

            if state[field] == 0 then
                ctx:emit("duration", endings[kind])
            end
        end
    end

    if state.heroism_aut == 0 and state.finesse_aut == 0 then
        ctx:remove(player, component.RELIGION_OKAWARU_STATUS)
    else
        ctx:set(player, component.RELIGION_OKAWARU_STATUS, state)
    end
end

-- A restored buff must still belong to a nonpenitent Okawaru worshipper;
-- bounded positive clocks keep consumers from reading forged durations.
function status.validate(ctx, player)
    for _, entity in ipairs(ctx:query({
        component.RELIGION_OKAWARU_STATUS,
    })) do
        local state = ctx:get(entity,
            component.RELIGION_OKAWARU_STATUS)
        local worship = ctx:get(player, component.RELIGION_WORSHIP)

        if entity ~= player or not worship or
            worship.god_id ~= gods.OKAWARU or
            (worship.penance[gods.OKAWARU] or 0) > 0 or
            state.heroism_aut < 0 or
            state.heroism_aut > okawaru.STATUS_CAP_AUT or
            state.finesse_aut < 0 or
            state.finesse_aut > okawaru.STATUS_CAP_AUT or
            (state.heroism_aut == 0 and state.finesse_aut == 0) then
            error("invalid Okawaru combat status")
        end
    end
end

return status
