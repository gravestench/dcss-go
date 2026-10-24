-- Finesse grants faster weapon and unarmed attacks. One saved Okawaru
-- status clock feeds both melee and ranged attack-delay policies.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local registry = require("policy.abilities.registry")
local status = require("policy.religion.okawaru.status")
local okawaru = require("constants.okawaru")

local finesse = {}

-- Rank and penance are checked live when the menu is drawn or invoked.
function finesse.available(ctx, player)
    return costs.available(ctx, player, gods.OKAWARU,
        okawaru.FINESSE_RANK)
end

-- Five MP must be present before this self-targeted action takes time.
function finesse.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, okawaru.FINESSE_MP) then
        return "You do not have enough magic."
    end

    return nil
end

-- A failed invocation spends a turn alone. Success refreshes the clock,
-- then pays five MP and the source generic three-point piety cost.
function finesse.resolve(ctx, player)
    if costs.failed(ctx, player, okawaru.FINESSE_FAIL_BASE,
        okawaru.FINESSE_FAIL_SCALE,
        okawaru.FINESSE_FAIL_PIETY) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    status.invoke(ctx, player, "finesse")
    costs.spend(ctx, player, okawaru.FINESSE_MP,
        costs.piety_cost(ctx, okawaru.FINESSE_PIETY))
end

registry.add(abilities.OKAWARU_FINESSE, {
    name = "Finesse",
    available = finesse.available,
    prepare = finesse.prepare,
    resolve = finesse.resolve,
})

return finesse
