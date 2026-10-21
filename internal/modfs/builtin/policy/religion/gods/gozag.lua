-- Gozag prices entry from the total gold generated on non-Abyss floors, not
-- from gold currently held or picked up. The wallet owns the historical
-- counter; this god module owns the fee formula and its eligibility message.
local component = require("constants.component")
local jobs = require("ids.jobs")
local sources = require("constants.religion_sources")

local gozag = {}

-- A Monk gets a free first patron. Any recorded prior patron ends that
-- exception, even if the Monk has since renounced all worship.
local function free_first_god(identity, worship)
    if identity.job_id ~= jobs.JOB_MONK then
        return false
    end

    for _, count in pairs(worship.worshipped) do
        if count > 0 then
            return false
        end
    end

    return true
end

-- Example: 100 generated gold gives a 25-gold fee even if only ten gold
-- pieces were picked up. C++ truncates the positive quotient toward zero.
function gozag.fee(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local wallet = ctx:get(player, component.WALLET)

    if not identity or not worship or not wallet then
        error("Gozag fee requires player, worship, and wallet state")
    end

    if free_first_god(identity, worship) then
        return 0
    end

    local generated = wallet.generated_gold
    local logarithm = math.log(generated + 10) / math.log(10)

    return math.floor((generated - generated / logarithm) / 2)
end

-- Permanent eligibility ignores the service fee; a player can return with
-- more gold later. Ecumenical conversion uses that permanent query too.
function gozag.check(ctx, player, temporary)
    if not temporary then
        return nil
    end

    local fee = gozag.fee(ctx, player)
    local wallet = ctx:get(player, component.WALLET)

    if wallet.gold < fee then
        return "Gozag requires a service fee of " .. fee .. " gold."
    end

    return nil
end

-- Charge the entry fee only after the common owner has selected this god.
-- The ecumenical altar temporarily ignores generated gold in the source,
-- so it also waives the fee while keeping the actual wallet untouched.
function gozag.join(ctx, player, _, source)
    if source == sources.ECUMENICAL then
        return
    end

    local fee = gozag.fee(ctx, player)
    local wallet = ctx:get(player, component.WALLET)

    if wallet.gold < fee then
        error("Gozag requires a service fee of " .. fee .. " gold.")
    end

    wallet.gold = wallet.gold - fee
    wallet.gozag_gold_used = wallet.gozag_gold_used + fee
    ctx:set(player, component.WALLET, wallet)
end

return gozag
