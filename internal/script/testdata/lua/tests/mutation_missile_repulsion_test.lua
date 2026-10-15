local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")
local ranged = require("policy.combat.ranged")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

local function scripted_rolls(expected_hit_bound)
    local draws = { 0, 6, 6, 50, 5, 0 }
    local next_draw = 0
    local ctx = {}

    function ctx.random(_, stream, bound)
        harness.equal(stream, "melee", "missile contact uses combat RNG")

        next_draw = next_draw + 1
        local draw = draws[next_draw]

        if next_draw == 1 then
            harness.equal(bound, expected_hit_bound,
                "missile repulsion changes the pre-roll hit bound")
            draw = math.floor(bound / 2)
        end

        if draw == nil or draw < 0 or draw >= bound then
            error("invalid scripted missile draw " .. tostring(next_draw))
        end

        return draw
    end

    return ctx
end

local function dart_outcome(repulsion)
    local defense = {
        ev = 6,
        ac = 0,
        gdr = 0,
        shield_class = 0,
        shield_blocks = 0,
        missile_repulsion = repulsion,
    }
    local hit_bound = repulsion and 10 or 20
    local ctx = scripted_rolls(hit_bound)

    return ranged.poison_dart(ctx, 1, defense)
end

function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player,
        mutations.MUT_DISTORTION_FIELD, 2)

    harness.equal(effects.sum(ctx, player,
        capabilities.MISSILE_REPULSION), 0,
        "Distortion Field below level three does not repel missiles")
    harness.equal(dart_outcome(false).kind, "hit",
        "the unrepelled dart clears the same EV roll")

    records.grant_acquired(ctx, player,
        mutations.MUT_DISTORTION_FIELD, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.MISSILE_REPULSION), 1,
        "Distortion Field level three grants missile repulsion")
    harness.equal(dart_outcome(true).kind, "dodge",
        "repulsion halves the monster hit bound before rolling")
end

return test
