-- Xom's Cleaving duration is a saved player component. Melee reads it to
-- make secondary attacks against adjacent hostiles for its full lifetime.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local streams = require("constants.rng_streams")
local cleaving = require("policy.religion.xom.cleaving")
local fixture = require("tests.monster_ally_support_fixture")
local monsters = require("ids.monsters")
local player_attack = require("policy.combat.player_attack")

local test = {}

-- Cleaving attacks every other adjacent hostile, but never reaches a
-- friendly, neutral, distant, dead, or primary target.
local function nearby_targets(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        30, 30, 100)
    local owner = fixture.context(ctx, player)
    local primary = fixture.actor(ctx, monsters.MONS_ORC,
        31, 30, 20)
    local secondary = fixture.actor(ctx, monsters.MONS_ORC,
        30, 31, 20)
    local distant = fixture.actor(ctx, monsters.MONS_ORC,
        32, 31, 20)
    local friendly = fixture.actor(ctx, monsters.MONS_ORC,
        29, 30, 20)

    ctx:add(friendly, component.SUMMON, {
        attitude = "friendly",
        source_id = "test",
        expires_aut = 100,
    })

    local found = cleaving.targets(owner, player, primary)

    harness.equal(#found, 1)
    harness.equal(found[1], secondary)
    harness.truthy(distant ~= secondary)
end

-- A secondary blow keeps the normal contact and AC rules, but scales the
-- raw damage before AC. High deterministic rolls make the ratio visible.
local function secondary_damage(ctx)
    local player = ctx:create()
    local owner = setmetatable({}, { __index = ctx })

    -- The damage policy reads this player for statuses and corrosion.
    function owner:player()
        return player
    end

    -- Return the largest legal roll to avoid incidental low-hit variance.
    function owner:random(_, bound)
        return bound - 1
    end

    local input = {
        strength = 10,
        dexterity = 10,
        damage_attribute = 10,
        fighting100 = 0,
        weapon100 = 0,
        using_weapon = true,
        weapon_damage = 10,
        weapon_plus = 0,
        defender_ac = 0,
    }
    local ordinary = player_attack.damage(owner, input)

    input.cleave_secondary = true

    harness.equal(player_attack.damage(owner, input),
        math.floor(ordinary * 7 / 10))
end

-- One minimum source roll gives ten turns. A second action extends the
-- current status, while elapsed aut eventually removes it completely.
function test.run(ctx)
    nearby_targets(ctx)
    secondary_damage(ctx)

    local player = ctx:create()
    local owner = setmetatable({}, {
        __index = ctx,
    })

    -- The event's duration draw belongs to Xom's Religion stream.
    function owner:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, 20)

        return 0
    end

    events.apply(owner, player, ids.GOOD_CLEAVING, 20, {
        stream = streams.RELIGION,
    })

    harness.equal(ctx:get(player,
        component.XOM_CLEAVING).remaining_aut, 100)
    harness.truthy(cleaving.active(ctx, player))

    events.apply(owner, player, ids.GOOD_CLEAVING, 20, {
        stream = streams.RELIGION,
    })

    harness.equal(ctx:get(player,
        component.XOM_CLEAVING).remaining_aut, 200)

    cleaving.tick(ctx, player, 200)

    harness.falsy(cleaving.active(ctx, player))
    harness.falsy(ctx:has(player, component.XOM_CLEAVING))
end

return test
