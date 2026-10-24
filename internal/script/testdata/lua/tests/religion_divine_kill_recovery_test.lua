-- Source kill recovery is a post-conduct reaction to a credited death.
-- These cases use real catalog traits and ECS pools rather than a copy of
-- god or monster definitions in the fixture.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local recovery = require("policy.religion.kill_recovery")
local streams = require("constants.rng_streams")

local test = {}

-- The live worship record, victim identity, and two resource pools are
-- enough to exercise recovery without recreating the death system.
local function world(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        10, 10, 50)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.MAGIC, {
        current = 5,
        max = 20,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.MAKHLEB,
        piety = 50,
        penance = {},
    })

    local messages = {}
    local draws = {}

    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    function game:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        local value = table.remove(draws, 1)

        harness.truthy(value and value >= 0 and value < bound,
            "unexpected divine recovery draw")

        return value
    end

    return game, player, messages, draws
end

-- Set a new patron without replacing the player's ECS identity or
-- resource pools, so each god sees the same source victim.
local function worship(ctx, player, god_id, piety, penance)
    ctx:set(player, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = piety,
        penance = penance or {},
    })
end

-- Makhleb heals from the victim's original HD. Vehumet returns MP and
-- The Shining One only helps for evil victims; all share the piety gate.
function test.run(ctx)
    local game, player, messages, draws = world(ctx)
    local rat = fixture.actor(ctx, monsters.MONS_RAT, 12, 10, 1)
    local rat_kind = catalog.get(categories.MONSTERS,
        monsters.MONS_RAT)
    local priest = fixture.actor(ctx, monsters.MONS_ORC_PRIEST,
        13, 10, 1)
    local priest_kind = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_PRIEST)

    -- A roll below the first-star threshold grants no recovery.
    draws[#draws + 1] = 29
    recovery.on_kill(game, player, rat, rat_kind, 10)
    harness.equal(ctx:get(player, component.HEALTH).current, 50)

    draws[#draws + 1] = 30
    recovery.on_kill(game, player, rat, rat_kind, 10)
    harness.equal(ctx:get(player, component.HEALTH).current, 51)
    harness.equal(messages[#messages], "You feel better.")

    worship(ctx, player, gods.VEHUMET, 50)
    draws[#draws + 1] = 30
    recovery.on_kill(game, player, rat, rat_kind, 10)
    harness.equal(ctx:get(player, component.MAGIC).current, 6)
    harness.equal(messages[#messages],
        "You feel your power returning.")

    worship(ctx, player, gods.SHINING_ONE, 50)
    draws[#draws + 1] = 30
    recovery.on_kill(game, player, rat, rat_kind, 10)
    harness.equal(ctx:get(player, component.HEALTH).current, 51)
    harness.equal(ctx:get(player, component.MAGIC).current, 6)

    draws[#draws + 1] = 30
    draws[#draws + 1] = 1
    draws[#draws + 1] = 1
    recovery.on_kill(game, player, priest, priest_kind, 10)
    harness.equal(ctx:get(player, component.HEALTH).current, 52)
    harness.equal(ctx:get(player, component.MAGIC).current, 7)

    -- Penance and source object bodies stop before the piety draw.
    worship(ctx, player, gods.MAKHLEB, 50, {
        [gods.MAKHLEB] = 1,
    })
    recovery.on_kill(game, player, rat, rat_kind, 10)
    harness.equal(#draws, 0)

    worship(ctx, player, gods.MAKHLEB, 50)
    local weapon = fixture.actor(ctx,
        monsters.MONS_DANCING_WEAPON, 14, 10, 1)
    local weapon_kind = catalog.get(categories.MONSTERS,
        monsters.MONS_DANCING_WEAPON)

    recovery.on_kill(game, player, weapon, weapon_kind, 10)
    harness.equal(#draws, 0)

    -- Death's Door blocks only the HP half of a valid TSO reaction.
    worship(ctx, player, gods.SHINING_ONE, 50)
    ctx:add(player, component.PLAYER_STATUS, {
        death_door_aut = 20,
    })
    draws[#draws + 1] = 30
    draws[#draws + 1] = 1
    draws[#draws + 1] = 1
    recovery.on_kill(game, player, priest, priest_kind, 10)
    harness.equal(ctx:get(player, component.HEALTH).current, 52)
    harness.equal(ctx:get(player, component.MAGIC).current, 8)

    -- Even an eligible kill cannot print gain messages for full pools.
    ctx:set(player, component.MAGIC, {
        current = 20,
        max = 20,
    })
    local before = #messages

    draws[#draws + 1] = 30
    draws[#draws + 1] = 1
    draws[#draws + 1] = 1
    recovery.on_kill(game, player, priest, priest_kind, 10)
    harness.equal(#messages, before)

    -- Vault-authored HD belongs to this individual monster. A modded
    -- body uses that saved HD, not its catalog kind's ordinary value.
    worship(ctx, player, gods.MAKHLEB, 50)
    ctx:set(player, component.HEALTH, {
        current = 50,
        max = 100,
    })
    ctx:set(player, component.PLAYER_STATUS, {
        death_door_aut = 0,
    })
    ctx:add(priest, component.VAULT_ACTOR_OVERRIDES, {
        hit_dice = 6,
    })

    draws[#draws + 1] = 30
    draws[#draws + 1] = 2
    recovery.on_kill(game, player, priest, priest_kind, 10)
    harness.equal(ctx:get(player, component.HEALTH).current, 55,
        "the individual victim's six HD drives healing")
end

return test
