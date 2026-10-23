-- Wu Jian's summon count and weapon rolls feed the real saved ECS summon,
-- equipment, ghost, and Barbs owners. No copied component schema is needed.
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local brands = require("constants.weapon_brands")
local wu_jian = require("policy.religion.wrath.wu_jian")

local test = {}

-- Zero card draws select three dire flails, their Vorpal ego, and the
-- Barbs branch. The ghost's strength uses full XL scaling, not card scaling.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 10, 10)
    local game = fixture.context(ctx, player)
    local card_bounds = {}
    local awaiting_gear = false
    local gear_seen = false
    local gear_batches = 0

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.PROGRESSION, { level = 9 })

    -- Override only the card stream; the shared summon and combat owners
    -- still receive their normal production draws on every other stream.
    function game:random(stream, bound)
        if stream == streams.MONSTER_GEAR then
            gear_seen = true

            return ctx:random(stream, bound)
        end

        if stream == streams.CARDS then
            card_bounds[#card_bounds + 1] = bound

            if bound == 8 then
                awaiting_gear = true
                gear_seen = false
            elseif bound == 5 and awaiting_gear then
                harness.truthy(gear_seen,
                    "ordinary monster gear rolls before Wu Jian's plus")
                gear_batches = gear_batches + 1
                awaiting_gear = false
            end

            return 0
        end

        return ctx:random(stream, bound)
    end

    harness.truthy(wu_jian.apply(game, player))

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned, 3)

    for _, creature in ipairs(summoned) do
        local state = ctx:get(creature, component.SUMMON)
        local ghost = ctx:get(creature, constructs.DANCING_WEAPON)

        harness.equal(state.source_id, gods.WU_JIAN)
        harness.truthy(ghost)

        for _, item in ipairs(ctx:query({ component.CARRIED_BY })) do
            if ctx:get(item, component.CARRIED_BY).holder == creature then
                local weapon = ctx:get(item, component.ITEM)

                harness.equal(weapon.kind_id, items.WPN_DIRE_FLAIL)
                harness.equal(weapon.ego, brands.VORPAL)
                harness.equal(weapon.plus, 0)
            end
        end
    end

    harness.equal(ctx:get(player, component.BARBS).remaining_aut, 50)
    harness.equal(ctx:get(player, component.BARBS).power, 0)
    harness.equal(gear_batches, 3)

    local expected = {
        3,
        6, 5, 8, 5,
        6, 5, 8, 5,
        6, 5, 8, 5,
        4, 6,
    }

    harness.equal(#card_bounds, #expected)

    for index, bound in ipairs(expected) do
        harness.equal(card_bounds[index], bound)
    end
end

return test
