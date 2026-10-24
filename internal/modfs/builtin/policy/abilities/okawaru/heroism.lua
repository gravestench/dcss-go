-- Heroism grants temporary effective martial skill, never skill XP.
-- The status owner supplies its clock and all combat skill projections.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local registry = require("policy.abilities.registry")
local status = require("policy.religion.okawaru.status")
local okawaru = require("constants.okawaru")

local heroism = {}

-- A saved menu row cannot bypass current worship, rank, or penance.
function heroism.available(ctx, player)
    return costs.available(ctx, player, gods.OKAWARU,
        okawaru.HEROISM_RANK)
end

-- Reject insufficient MP before an ability intent can spend time.
function heroism.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, okawaru.HEROISM_MP) then
        return "You do not have enough magic."
    end

    return nil
end

-- Source failure spends time alone; success extends Heroism and pays
-- two MP plus the ordinary one-point piety cost.
function heroism.resolve(ctx, player)
    if costs.failed(ctx, player, okawaru.HEROISM_FAIL_BASE,
        okawaru.HEROISM_FAIL_SCALE,
        okawaru.HEROISM_FAIL_PIETY) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    status.invoke(ctx, player, "heroism")
    costs.spend(ctx, player, okawaru.HEROISM_MP,
        costs.piety_cost(ctx, okawaru.HEROISM_PIETY))
end

registry.add(abilities.OKAWARU_HEROISM, {
    name = "Heroism",
    available = heroism.available,
    prepare = heroism.prepare,
    resolve = heroism.resolve,
})

return heroism
