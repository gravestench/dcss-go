-- Theory of operation: every source of residual magical contamination
-- changes the same saved player component here. Zin is notified from the
-- transition itself, so a new cloud, trap, or spell cannot silently skip
-- the first-glow warning or controlled extra-glow offense.
local component = require("constants.component")
local gods = require("constants.gods")
local kinds = require("constants.religion_conduct")
local conduct = require("policy.religion.conduct")
local ids = require("policy.magic.effects.zaps.ids")

local contamination = {}
local MAX_AMOUNT = 250000

-- The source's display tiers are nonlinear. Tier three is the first
-- severe glow; the same tiers determine how much extra controlled glow
-- offends Zin after the warning has already happened.
function contamination.level(amount)
    if amount > 60000 then
        return math.floor(amount / 20000) + 4
    elseif amount > 40000 then
        return 6
    elseif amount > 25000 then
        return 5
    elseif amount > 15000 then
        return 4
    elseif amount > 5000 then
        return 3
    elseif amount > 3000 then
        return 2
    elseif amount > 0 then
        return 1
    end

    return 0
end

-- `controlled` means the player chose the action causing the increase.
-- On first severe glow the source warns even for an involuntary effect;
-- further controlled additions offend Zin at one plus the new tier.
function contamination.change(ctx, player, delta, controlled)
    if type(delta) ~= "number" or delta % 1 ~= 0 then
        error("contamination change requires an integer amount")
    end

    local state = ctx:get(player, ids.component.CONTAMINATION)
    local old_amount = state and state.amount or 0
    local new_amount = math.max(0,
        math.min(MAX_AMOUNT, old_amount + delta))

    if new_amount == 0 then
        if state then
            ctx:remove(player, ids.component.CONTAMINATION)
        end
    elseif state then
        state.amount = new_amount
        ctx:set(player, ids.component.CONTAMINATION, state)
    else
        ctx:add(player, ids.component.CONTAMINATION, {
            amount = new_amount,
        })
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not worship or worship.god_id ~= gods.ZIN then
        return new_amount
    end

    local old_level = contamination.level(old_amount)
    local new_level = contamination.level(new_amount)
    local severity
    local known

    if old_level < 3 and new_level >= 3 then
        severity = 0
        known = false
    elseif controlled and delta > 0 and old_level >= 3 then
        severity = 1 + new_level
        known = true
    end

    if severity then
        conduct.record(ctx, {
            id = kinds.CAUSE_GLOWING,
            level = severity,
            known = known,
        })
    end

    return new_amount
end

return contamination
