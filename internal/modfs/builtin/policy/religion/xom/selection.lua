-- Xom tests candidate actions in source priority, not catalog load order.
-- Each named gate will remain small enough to explain its probability and
-- eligibility without a switch over all forty-two effects.
local component = require("constants.component")
local bad = require("policy.religion.xom.selection_bad")
local chance = require("policy.religion.xom.selection_chance")
local good = require("policy.religion.xom.selection_good")
local gods = require("constants.gods")
local limits = require("constants.piety")
local xom_state = require("policy.religion.xom.state")
local streams = require("constants.rng_streams")

local selection = {}

-- One bounded pass can return no action. The source retries forever, but
-- a finite result keeps broken mod eligibility from hanging the turn.
function selection.choose(ctx, player, nice, severity, tension, stream)
    stream = stream or streams.RELIGION
    severity = math.max(1, severity)

    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local worships_xom = state and state.god_id == gods.XOM

    if nice then
        if tension == 0 and worships_xom and
            not chance.in_y(ctx, stream, state.piety, limits.MAX) then
            return nil
        end

        return good.choose(ctx, player, severity, tension, stream)
    end

    if not xom_state.feels_nasty(state) and
        tension > ctx:random(stream, 10) and
        worships_xom and chance.in_y(ctx, stream, state.piety, limits.MAX) then
        return nil
    end

    return bad.choose(ctx, player, state, severity, tension, stream)
end

return selection
