
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local icy_defense = require("policy.character.icy_defense")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local resistances = require("constants.resistance_ids")
local harness = require("tests.harness")

local test = {}

-- Read one active Icy Defence capability after changing its timer.
local function bonus(ctx, player, capability)
    return effects.sum(ctx, player, capability)
end

-- Condensation Shield SH returns after recovery.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.ICY_DEFENSE, { remaining_aut = 0 })
    records.grant_acquired(ctx, player, mutations.MUT_ICEMAIL, 2)
    records.grant_acquired(ctx, player,
        mutations.MUT_CONDENSATION_SHIELD, 1)

    harness.equal(bonus(ctx, player, capabilities.AC_PARTIAL_X100), 800,
        "Icemail level two grants eight AC while active")
    harness.equal(bonus(ctx, player, capabilities.SHIELD_CLASS_BONUS), 8,
        "Condensation Shield grants four displayed SH")

    icy_defense.melt(ctx, player, resistances.COLD)

    harness.equal(ctx:get(player, component.ICY_DEFENSE).remaining_aut, 0,
        "cold does not melt icy defenses")

    icy_defense.melt(ctx, player, resistances.FIRE)

    harness.equal(ctx:get(player, component.ICY_DEFENSE).remaining_aut, 300,
        "fire depletes icy defenses for thirty turns")
    harness.equal(bonus(ctx, player, capabilities.AC_PARTIAL_X100), 0,
        "depleted Icemail grants no AC")
    harness.equal(bonus(ctx, player, capabilities.SHIELD_CLASS_BONUS), 0,
        "depleted Condensation Shield grants no SH")

    icy_defense.tick(ctx, player, 10)

    harness.equal(ctx:get(player, component.ICY_DEFENSE).remaining_aut, 290,
        "depletion decays with elapsed action time")

    icy_defense.melt(ctx, player, resistances.STEAM)

    harness.equal(ctx:get(player, component.ICY_DEFENSE).remaining_aut, 300,
        "another heat hit refreshes depletion")

    icy_defense.tick(ctx, player, 300)

    harness.equal(ctx:get(player, component.ICY_DEFENSE).remaining_aut, 0,
        "icy defenses recover when the timer expires")
    harness.equal(bonus(ctx, player, capabilities.AC_PARTIAL_X100), 800,
        "Icemail AC returns after recovery")
    harness.equal(bonus(ctx, player, capabilities.SHIELD_CLASS_BONUS), 8,
        "Condensation Shield SH returns after recovery")

    local envelope = ctx:create()

    ctx:add(envelope, component.ICY_DEFENSE, { remaining_aut = 0 })
    records.grant_acquired(ctx, envelope, mutations.MUT_ICEMAIL, 1)
    icy_defense.melt(ctx, envelope, resistances.FIRE)

    harness.equal(ctx:get(envelope, component.ICY_DEFENSE).remaining_aut, 0,
        "Icemail alone is not depleted by source heat hook")
end

return test
