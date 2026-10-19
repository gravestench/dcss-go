
local component = require("constants.component")
local harness = require("tests.harness")
local catalog = require("policy.catalog")
local enchant = require("policy.combat.monster_enchant")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local senses = require("policy.character.senses")

local test = {}

-- An ordinary player cannot identify an innately invisible monster.
function test.run(ctx)
    local player = ctx:create()
    local monster = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_UNSEEN_HORROR,
        speed = 10,
    })
    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = 3,
        y = 1,
    })

    harness.equal(senses.perceive(ctx, player, monster, true), "unseen",
        "an ordinary player cannot identify an innately invisible monster")

    records.grant_acquired(ctx, player, mutations.MUT_ANTENNAE, 1)

    harness.equal(senses.detect_radius(ctx, player), 2,
        "each antennae level detects monsters two cells farther")
    -- Detection reveals position without granting the visual identity of an invisible actor.
    harness.equal(senses.perceive(ctx, player, monster, true), "detected",
        "antennae locate but do not identify an invisible monster")

    ctx:set(monster, component.POSITION, {
        level_id = 1,
        x = 4,
        y = 1,
    })

    harness.equal(senses.perceive(ctx, player, monster, true), "unseen",
        "antennae detection stops beyond its source radius")

    ctx:set(monster, component.POSITION, {
        level_id = 1,
        x = 3,
        y = 2,
    })

    harness.equal(senses.perceive(ctx, player, monster, false, true),
        "detected", "antennae sense a monster behind known walls")
    -- Known terrain gates detection output even when the monster is within radius.
    harness.equal(senses.perceive(ctx, player, monster, false, false),
        "unseen", "unexplored cells do not reveal monster positions")

    ctx:set(monster, component.POSITION, {
        level_id = 1,
        x = 4,
        y = 1,
    })

    records.grant_acquired(ctx, player, mutations.MUT_ACUTE_VISION, 1)

    harness.equal(senses.perceive(ctx, player, monster, true), "visible",
        "acute vision identifies an invisible monster in sight")

    records.grant_acquired(ctx, player, mutations.MUT_ANTENNAE, 2)

    -- The highest antennae rank crosses from detection into direct identification.
    harness.truthy(senses.see_invisible(ctx, player),
        "three antennae levels grant see invisible")

    local antennae_only = ctx:create()

    records.grant_acquired(ctx, antennae_only, mutations.MUT_ANTENNAE, 3)
    harness.truthy(senses.see_invisible(ctx, antennae_only),
        "antennae grant see invisible without acute vision")

    local eyeballs_only = ctx:create()

    records.grant_acquired(ctx, eyeballs_only, mutations.MUT_EYEBALLS, 3)
    harness.truthy(senses.see_invisible(ctx, eyeballs_only),
        "level-three eyeballs also grant source see invisible")

    local ordinary = ctx:create()

    ctx:add(ordinary, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:set(monster, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:set(monster, component.POSITION, {
        level_id = 1,
        x = 3,
        y = 1,
    })
    ctx:add(monster, component.MONSTER_ENCHANT, {
        invisible_aut = 20,
    })

    harness.equal(senses.perceive(ctx, ordinary, monster, true), "unseen",
        "temporary invisibility also hides an ordinary monster")
    harness.truthy(enchant.can_dispel(ctx, monster),
        "temporary invisibility is dispellable")

    local world = setmetatable({}, { __index = ctx })

    -- Capture senses events separately from the policy state being asserted.
    function world.emit() end

    -- Expiry messages ask who observes this actor in a live game.
    function world.player()
        return player
    end

    -- This test holds geometry open while varying actor invisibility.
    function world.visible()
        return true
    end

    enchant.tick(world, monster)
    harness.equal(ctx:get(monster, component.MONSTER_ENCHANT).invisible_aut,
        10, "temporary invisibility advances on the monster clock")
    enchant.tick(world, monster)
    harness.equal(ctx:get(monster, component.MONSTER_ENCHANT), nil,
        "expired invisibility leaves no status component")

    ctx:add(monster, component.MONSTER_ENCHANT, {
        invisible_aut = 20,
    })

    enchant.dispel(world, monster, catalog.get("monsters", monsters.MONS_RAT))
    harness.equal(ctx:get(monster, component.MONSTER_ENCHANT), nil,
        "dispel removes temporary invisibility")
end

return test
