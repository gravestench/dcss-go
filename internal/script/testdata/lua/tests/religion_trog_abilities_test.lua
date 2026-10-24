-- Trog's three active powers read the same saved worship component as
-- combat and god gifts. This exercises the production ability registry.
local abilities = require("ids.abilities")
local berserk = require("policy.abilities.trog.berserk")
local component = require("constants.component")
local commands = require("policy.commands.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local mutation_classes = require("constants.mutation_classes")
local mutation_records = require("policy.mutations.records")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local rage = require("policy.character.rage")
local species = require("ids.species")
local zap = require("policy.magic.effects.zaps.ids").component

local test = {}

-- Use real player and worship schemas; only the player accessor is
-- supplied because the Lua harness has no terminal Game wrapper.
local function worshipper(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })

    -- The ability registry asks the same player accessor as a live game.
    function game:player()
        return player
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Trog ability tester",
    })
    ctx:add(player, component.PROGRESSION, { level = 10 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.HEALTH, {
        current = 30,
        max = 30,
    })
    ctx:add(player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })
    ctx:add(player, component.DURATIONS, {
        might_aut = 0,
        haste_aut = 0,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.TROG,
        piety = piety.breakpoint(1),
        penance = {},
    })

    return game, player
end

-- A failed power spends no piety or MP. A successful one starts the
-- shared rage component and pays Trog only after that effect exists.
local function rage_action(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    worship.penance[gods.TROG] = 0
    worship.piety = 35
    game:set(player, component.RELIGION_WORSHIP, worship)

    -- Low draws make the one-star invocation fail deterministically.
    function game:random(_, bound)
        return 0
    end

    berserk.resolve(game, player)
    harness.falsy(rage.active(game, player))
    harness.equal(game:get(player, component.RELIGION_WORSHIP).piety, 35)

    worship.piety = 200
    game:set(player, component.RELIGION_WORSHIP, worship)

    -- High draws permit the same ability through the shared failure gate.
    function game:random(_, bound)
        return bound - 1
    end

    berserk.resolve(game, player)
    harness.truthy(rage.active(game, player))
    harness.truthy(game:get(player,
        component.RELIGION_WORSHIP).piety < 200)
    harness.equal(game:get(player, component.MAGIC).current, 10)
end

-- Source ranks are one, two, and four. Penance hides all three even
-- while the stored piety remains above their thresholds.
local function gates(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)
    local berserk = registry.get(abilities.TROG_BERSERK)
    local hand = registry.get(abilities.TROG_HAND)
    local brothers = registry.get(abilities.TROG_BROTHERS_IN_ARMS)

    harness.truthy(berserk)
    harness.truthy(hand)
    harness.truthy(brothers)
    harness.truthy(registry.usable_now(game, player, berserk))
    harness.falsy(registry.usable_now(game, player, hand))

    worship.piety = piety.breakpoint(2)
    game:set(player, component.RELIGION_WORSHIP, worship)
    harness.truthy(registry.usable_now(game, player, hand))
    harness.falsy(registry.usable_now(game, player, brothers))

    worship.piety = piety.breakpoint(4)
    game:set(player, component.RELIGION_WORSHIP, worship)
    harness.truthy(registry.usable_now(game, player, brothers))

    worship.penance[gods.TROG] = 1
    game:set(player, component.RELIGION_WORSHIP, worship)
    harness.falsy(registry.usable_now(game, player, berserk))
    harness.falsy(registry.usable_now(game, player, hand))
    harness.falsy(registry.usable_now(game, player, brothers))
end

-- Trog does not train Invocations. The failure owner therefore reads
-- piety alone for these three source tuples.
local function failure(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    worship.piety = 100
    game:set(player, component.RELIGION_WORSHIP, worship)

    harness.equal(costs.failure_chance(game, player, 45, 0, 2), 0)
    harness.equal(costs.failure_chance(game, player, 75, 0, 1), 0)
    harness.equal(costs.failure_chance(game, player, 160, 0, 1), 60)
end

-- Deliberate Trog rage and a potion bypass Clarity, while involuntary
-- rage does not. Confusion prevents all three divine command preflights.
local function source_gates(game, player)
    local worship = game:get(player, component.RELIGION_WORSHIP)

    worship.penance[gods.TROG] = 0
    worship.piety = 200
    game:set(player, component.RELIGION_WORSHIP, worship)

    mutation_records.grant_acquired(game, player,
        mutations.MUT_CLARITY, 1)
    harness.falsy(rage.can_begin(game, player))
    harness.truthy(rage.can_begin(game, player, true, false))
    harness.truthy(rage.can_begin(game, player, false, true))
    mutation_records.delete(game, player, mutations.MUT_CLARITY,
        mutation_classes.ACQUIRED, 1)

    game:add(player, zap.PLAYER_CONFUSION, { remaining_aut = 10 })

    for _, id in ipairs({
        abilities.TROG_BERSERK,
        abilities.TROG_HAND,
        abilities.TROG_BROTHERS_IN_ARMS,
    }) do
        local result = commands.prepare(game, player, {
            ability_id = id,
        })

        harness.equal(result.message, "You are too confused!")
    end

    game:remove(player, zap.PLAYER_CONFUSION)

    -- A bow cannot be fired during rage, so deliberate invocation asks
    -- before a timed action. Confirmation reuses the same live equipment.
    game:add(player, component.ITEM_KNOWLEDGE, {})

    local bow = game:create()

    game:add(bow, component.ITEM, {
        kind_id = items.WPN_SHORTBOW,
        quantity = 1,
    })
    game:add(bow, component.CARRIED_BY, { holder = player })
    game:add(bow, component.EQUIPPED, { slot = "weapon" })

    local warning = berserk.prepare(game, player, {})

    harness.truthy(warning.confirmation)
    harness.equal(berserk.prepare(game, player, { forced = true }), nil)
end

-- One test entry runs both menu state and the arithmetic they share.
function test.run(ctx)
    local game, player = worshipper(ctx)

    gates(game, player)
    failure(game, player)
    source_gates(game, player)
    rage_action(game, player)
end

return test
