local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local harness = require("tests.harness")
local melee = require("policy.combat.melee")
local mutations = require("ids.mutations")
local ranged = require("policy.combat.ranged")
local records = require("policy.mutations.records")

local test = {}

local function scripted_contact(expected_bound)
    local draws = { 0, 10, 10, 50, 5, 0 }
    local next_draw = 0
    local ctx = {}

    function ctx.random(_, stream, bound)
        harness.equal(stream, "melee", "monster contact uses melee RNG")

        next_draw = next_draw + 1
        local drawn = draws[next_draw]

        if next_draw == 1 then
            harness.equal(bound, expected_bound,
                "monster accuracy modifies the hit-roll bound")
            drawn = math.floor(bound / 2)
        end

        if drawn == nil or drawn < 0 or drawn >= bound then
            error("invalid translucent-skin contact draw " .. next_draw)
        end

        return drawn
    end

    return ctx
end

local function defense(modifier)
    return {
        ev = 6,
        shield_class = 0,
        shield_blocks = 0,
        visible_hit_modifier = modifier,
    }
end

function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player,
        mutations.MUT_TRANSLUCENT_SKIN, 1)

    local modifier = effects.sum(ctx, player,
        capabilities.VISIBLE_DEFENDER_HIT_MODIFIER)

    harness.equal(modifier, -2,
        "one Translucent Skin level removes two pre-roll monster hit points")
    harness.equal(melee.monster_contact(scripted_contact(20),
        { hd = 1 }, defense(0)).kind, "hit",
        "ordinary melee attack clears the source EV roll")
    harness.equal(melee.monster_contact(scripted_contact(18),
        { hd = 1 }, defense(modifier)).kind, "dodge",
        "Translucent Skin changes the same melee contact to a dodge")

    local ordinary_dart = ranged.poison_dart(scripted_contact(20), 1,
        defense(0))
    local translucent_dart = ranged.poison_dart(scripted_contact(18), 1,
        defense(modifier))

    harness.equal(ordinary_dart.kind, "hit",
        "ordinary ranged attack clears the source EV roll")
    harness.equal(translucent_dart.kind, "dodge",
        "Translucent Skin changes the same dart contact to a dodge")

    records.grant_acquired(ctx, player,
        mutations.MUT_TRANSLUCENT_SKIN, 2)

    harness.equal(effects.sum(ctx, player,
        capabilities.VISIBLE_DEFENDER_HIT_MODIFIER), -6,
        "three Translucent Skin levels remove six hit points")
end

return test
