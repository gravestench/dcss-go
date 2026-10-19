-- Friendly Freeze must affect the monster foe without reporting unseen combat.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local freeze = require("policy.combat.monster_spells.freeze")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local catalog = require("policy.catalog")
local exposure = require("policy.magic.effects.statuses.monster_cold_exposure")

local test = {}

-- Freeze a cold-blooded survivor with a scripted exposure coin flip. The
-- production status owner must save its reduced speed and duration, while
-- the message log depends on whether the player can see the victim.
function test.run(ctx)
    local player = ctx:create()
    local caster = fixture.actor(ctx, monsters.MONS_ENDOPLASM, 1, 1, 40)
    local foe = fixture.actor(ctx, monsters.MONS_ADDER, 2, 1, 40)
    local game = fixture.context(ctx, player)
    local messages = {}
    local seen = false
    local draws = 0

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    -- These draws guarantee minimum cold damage and successful exposure.
    function game:random(stream)
        harness.equal(stream, streams.MONSTER_SPELL,
            "Freeze and its exposure share the monster spell stream")
        draws = draws + 1

        return 0
    end

    -- Sight is the only variable between the two otherwise identical casts.
    function game:visible(_, from_x, from_y, radius, x, y)
        local distance = math.max(math.abs(from_x - x),
            math.abs(from_y - y))

        return seen and distance <= radius
    end

    -- Record only public messages, not internal health and status changes.
    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    local plan = freeze.plan(game, caster, foe)

    harness.truthy(plan, "adjacent monster foe can receive Freeze")
    freeze.resolve(game, caster, foe, nil, plan)

    local slow = ctx:get(foe, component.PROJECTILE_SLOW)

    harness.truthy(slow and slow.remaining_aut > 0,
        "cold-blooded survivor gains saved slow")
    harness.truthy(ctx:get(foe, component.ACTOR).speed < 10,
        "cold exposure reduces the foe's speed")
    harness.equal(#messages, 0,
        "offscreen freeze and slow reveal no foe")

    -- Geometric sight still cannot name an invisible monster. This catches
    -- accidental use of ctx:visible without the player's perception rule.
    seen = true
    ctx:add(foe, component.MONSTER_ENCHANT, {
        invisible_aut = 100,
    })
    freeze.resolve(game, caster, foe, nil, plan)

    harness.equal(#messages, 0,
        "visible cell does not reveal invisible foe")

    ctx:remove(foe, component.MONSTER_ENCHANT)
    records.grant_acquired(ctx, player, mutations.MUT_NIGHTSTALKER, 2)
    freeze.resolve(game, caster, foe, nil, plan)

    harness.equal(#messages, 0,
        "Nightstalker keeps a distant foe outside actual player sight")

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 3,
        y = 3,
    })
    freeze.resolve(game, caster, foe, nil, plan)

    harness.truthy(#messages > 0,
        "a visible freeze reports its result")

    -- Source consumes both exposure draws before rejecting a stationary
    -- tentacle's slow. The RNG record must match even without status state.
    local stationary = fixture.actor(ctx, monsters.MONS_KRAKEN_TENTACLE,
        2, 2, 40)
    local definition = catalog.get("monsters",
        monsters.MONS_KRAKEN_TENTACLE)
    local before = draws

    exposure.apply(game, stationary, definition, 5,
        streams.MONSTER_SPELL)

    harness.equal(draws - before, 2,
        "stationary cold-blooded foe consumes exposure draws")
    harness.falsy(ctx:has(stationary, component.PROJECTILE_SLOW),
        "stationary foe receives no slow")
end

return test
