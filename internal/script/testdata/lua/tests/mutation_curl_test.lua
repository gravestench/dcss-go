local component = require("constants.component")
local causes = require("constants.damage_causes")
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local curl = require("policy.character.curl")
local effects = require("policy.mutations.effects.registry")
local health = require("policy.combat.player_health")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

local function armour(ctx, player)
    return effects.full_sum(ctx, player, capabilities.AC_FULL_X100)
end

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = 30,
        max = 30,
    })
    records.grant_acquired(ctx, player, mutations.MUT_CURL, 1)

    harness.equal(armour(ctx, player), 0,
        "Curl grants no AC before an eligible hit")

    health.damage(ctx, player, 1, false, nil, causes.POISON)
    health.damage(ctx, player, 1, false, nil, causes.CLOUD)

    harness.falsy(curl.active(ctx, player),
        "poison and clouds do not trigger Curl")

    health.damage(ctx, player, 1, false, nil, causes.HIT)

    harness.truthy(curl.active(ctx, player),
        "an impact triggers Curl")
    harness.equal(armour(ctx, player), 700,
        "Curl grants seven AC against later hits")

    curl.reset(ctx, player)

    harness.falsy(curl.active(ctx, player),
        "Curl clears before the next monster phase")
    harness.equal(armour(ctx, player), 0,
        "Curl AC disappears when uncurling")
end

return test
