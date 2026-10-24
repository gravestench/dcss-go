-- Fixed draws protect Xom's source priority before adding later gates.
-- The first passing gate must win without an unbounded retry loop.
local component = require("constants.component")
local events = require("ids.xom_events")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local selection = require("policy.religion.xom.selection")
local good = require("policy.religion.xom.selection_good")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- Fail at the exact unexpected draw so a new selection check cannot
-- silently change the seeded result of the first source gate.
local function fixed_draws(ctx, expected)
    local index = 0
    local proxy = setmetatable({}, { __index = ctx })

    function proxy:random(stream, bound)
        index = index + 1

        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, expected[index].bound)

        return expected[index].value
    end

    function proxy:draws_used()
        return index
    end

    return proxy
end

-- Good potion is considered before divination while combat tension exists.
local function first_good_gate(ctx, player)
    local proxy = fixed_draws(ctx, {
        { bound = 3, value = 0 },
        { bound = 50, value = 0 },
    })

    local chosen = selection.choose(proxy, player, true, 50, 2,
        streams.RELIGION)

    harness.equal(chosen, events.GOOD_POTION)
    harness.equal(proxy:draws_used(), 2)
end

-- Once potion and divination fail, the spell gate probes the severity
-- prefix of ordinary player spells before later helpful choices.
local function spell_good_gate(ctx, player)
    local proxy = fixed_draws(ctx, {
        { bound = 3, value = 2 },
        { bound = 4, value = 3 },
        { bound = 4, value = 0 },
    })

    harness.equal(selection.choose(proxy, player, true, 4, 2,
        streams.RELIGION), events.GOOD_SPELL)
    harness.equal(proxy:draws_used(), 3)
end

-- With no danger and zero piety, suppression is certain. The source's
-- x_chance_in_y consumes no RNG for this impossible success chance.
local function zero_tension_suppression(ctx, player)
    local proxy = fixed_draws(ctx, {})

    local chosen = selection.choose(proxy, player, true, 50, 0,
        streams.RELIGION)

    harness.equal(chosen, nil)
    harness.equal(proxy:draws_used(), 0)
end

-- High piety permits an idle good action. Cloud trail follows the failed
-- spell probe and only wins while no trail is already active.
local function cloud_trail_good_gate(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = 200
    ctx:set(player, component.RELIGION_WORSHIP, worship)

    local proxy = fixed_draws(ctx, {
        { bound = 3, value = 0 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 0 },
    })

    harness.equal(selection.choose(proxy, player, true, 20, 0,
        streams.RELIGION), events.GOOD_CLOUD_TRAIL)
    harness.equal(proxy:draws_used(), 4)

    worship.piety = 0
    ctx:set(player, component.RELIGION_WORSHIP, worship)
end

-- After the idle cloud gate is skipped, a visible hostile makes both
-- confusion and enchantment meaningful in their source priority order.
local function hostile_good_gates(ctx, player)
    local owner = fixture.context(ctx, player)
    local monster = fixture.actor(ctx, monsters.MONS_ORC, 9, 7, 20)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    local confuse = fixed_draws(owner, {
        { bound = 3, value = 2 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 0 },
    })

    harness.equal(selection.choose(confuse, player, true, 20, 2,
        streams.RELIGION), events.GOOD_CONFUSION)

    local enchant = fixed_draws(owner, {
        { bound = 3, value = 2 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 0 },
    })

    harness.equal(selection.choose(enchant, player, true, 20, 2,
        streams.RELIGION), events.GOOD_ENCHANT_MONSTER)

    ctx:destroy(monster)
    ctx:remove(player, component.POSITION)
end

-- The source scenery fallback can fire even with no fountain or door.
-- Its one-in-eight roll follows the failed normal scenery branch.
local function scenery_fallback_gate(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = 200
    ctx:set(player, component.RELIGION_WORSHIP, worship)

    local proxy = fixed_draws(ctx, {
        { bound = 3, value = 0 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 5, value = 0 },
        { bound = 5, value = 0 },
        { bound = 8, value = 0 },
    })

    harness.equal(selection.choose(proxy, player, true, 20, 0,
        streams.RELIGION), events.GOOD_SCENERY)
    harness.equal(proxy:draws_used(), 7)

    worship.piety = 0
    ctx:set(player, component.RELIGION_WORSHIP, worship)
end

-- A visible hostile snake makes Snakes to Sticks eligible after scenery
-- fails. The selector uses the effect's genus test, so every snake kind
-- follows the same rule without a second ID list.
local function snake_good_gate(ctx, player)
    local owner = fixture.context(ctx, player)
    local snake = fixture.actor(ctx, monsters.MONS_ADDER, 9, 7, 12)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    local proxy = fixed_draws(owner, {
        { bound = 3, value = 2 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 5, value = 4 },
        { bound = 5, value = 4 },
        { bound = 20, value = 19 },
        { bound = 8, value = 7 },
        { bound = 20, value = 0 },
    })

    harness.equal(good.choose(proxy, player, 20, 0,
        streams.RELIGION), events.GOOD_SNAKES)
    harness.equal(proxy:draws_used(), 9)

    ctx:destroy(snake)
    ctx:remove(player, component.POSITION)
end

-- Group allies are considered only after Snakes to Sticks. The tension
-- draw and chance draw must precede the shared No Love restriction.
local function allies_good_gate(ctx, player)
    local proxy = fixed_draws(ctx, {
        { bound = 3, value = 0 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 5, value = 4 },
        { bound = 5, value = 4 },
        { bound = 20, value = 19 },
        { bound = 8, value = 7 },
        { bound = 20, value = 19 },
        { bound = 10, value = 0 },
        { bound = 20, value = 0 },
    })

    harness.equal(good.choose(proxy, player, 20, 2,
        streams.RELIGION), events.GOOD_ALLIES)
    harness.equal(proxy:draws_used(), 13)
end

-- A safe early bad action is the harmless pseudo-miscast. Severity four
-- keeps it non-nasty even when Xom's later harmful stages are available.
local function first_bad_gate(ctx, player)
    local proxy = fixed_draws(ctx, {
        { bound = 10, value = 0 },
        { bound = 4, value = 0 },
    })

    local chosen = selection.choose(proxy, player, false, 4, 0,
        streams.RELIGION)

    harness.equal(chosen, events.BAD_MISCAST_PSEUDO)
    harness.equal(proxy:draws_used(), 2)
end

-- A hostile in sight makes the enchant and blink gates eligible. Earlier
-- failures must consume their draws before either later action can win.
local function hostile_bad_gates(ctx, player)
    local owner = fixture.context(ctx, player)
    local monster = fixture.actor(ctx, monsters.MONS_ORC, 9, 7, 20)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    local enchant = fixed_draws(owner, {
        { bound = 10, value = 9 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 0 },
    })

    harness.equal(selection.choose(enchant, player, false, 20, 2,
        streams.RELIGION), events.BAD_ENCHANT_MONSTER)
    harness.equal(enchant:draws_used(), 4)

    local blink = fixed_draws(owner, {
        { bound = 10, value = 9 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 0 },
    })

    harness.equal(selection.choose(blink, player, false, 20, 2,
        streams.RELIGION), events.BAD_BLINK_MONSTERS)
    harness.equal(blink:draws_used(), 5)

    local confuse = fixed_draws(owner, {
        { bound = 10, value = 9 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 0 },
    })

    harness.equal(selection.choose(confuse, player, false, 20, 2,
        streams.RELIGION), events.BAD_CONFUSION)
    harness.equal(confuse:draws_used(), 6)

    local swap = fixed_draws(owner, {
        { bound = 10, value = 9 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 0 },
    })

    harness.equal(selection.choose(swap, player, false, 20, 2,
        streams.RELIGION), events.BAD_SWAP_MONSTERS)
    harness.equal(swap:draws_used(), 7)

    local polymorph = fixed_draws(owner, {
        { bound = 10, value = 9 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 19 },
        { bound = 20, value = 0 },
    })

    harness.equal(selection.choose(polymorph, player, false, 20, 2,
        streams.RELIGION), events.BAD_POLYMORPH)
    harness.equal(polymorph:draws_used(), 10)

    ctx:destroy(monster)
    ctx:remove(player, component.POSITION)
end

-- Use production worship schema and IDs; only the random source is fixed.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.XOM,
        piety = 0,
        gift_timeout = 10,
    })

    first_good_gate(ctx, player)
    spell_good_gate(ctx, player)
    zero_tension_suppression(ctx, player)
    cloud_trail_good_gate(ctx, player)
    hostile_good_gates(ctx, player)
    scenery_fallback_gate(ctx, player)
    snake_good_gate(ctx, player)
    allies_good_gate(ctx, player)
    first_bad_gate(ctx, player)
    hostile_bad_gates(ctx, player)
end

return test
