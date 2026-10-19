-- Example: A qualifying hit sets Curl for the monster phase; reset clears it afterward.
local causes = require("constants.damage_causes")
local component = require("constants.component")
local mutations = require("ids.mutations")
local levels = require("policy.mutations.levels")

local curl = {}

-- Read the reaction bit retained across the monster phase after a qualifying hit.
function curl.active(ctx, player)
    local state = ctx:get(player, component.CURL)

    return state and state.active or false
end

-- Source: ouch.cc:_consider_curling responds to direct hits, beams, traps,
-- and explosions. Ongoing poison and cloud damage do not curl the player.
function curl.on_damage(ctx, player, amount, cause)
    if amount <= 0 or cause ~= causes.HIT or
        levels.effective(ctx, player, mutations.MUT_CURL) == 0 or
        curl.active(ctx, player) then
        return
    end

    local state = ctx:get(player, component.CURL)

    if state then
        state.active = true
        ctx:set(player, component.CURL, state)
    else
        ctx:add(player, component.CURL, { active = true })
    end
end

-- Leaving the threatened damage sequence clears the temporary curl bonus.
function curl.reset(ctx, player)
    local state = ctx:get(player, component.CURL)

    if not state or not state.active then
        return
    end

    state.active = false
    ctx:set(player, component.CURL, state)
end

return curl
