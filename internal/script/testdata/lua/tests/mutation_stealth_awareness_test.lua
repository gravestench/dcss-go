
local component = require("constants.component")
local armour_egos = require("constants.armour_egos")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local species = require("ids.species")
local awareness = require("policy.ai.awareness")
local stealth = require("policy.character.stealth")
local records = require("policy.mutations.records")

local test = {}

-- Pin awareness RNG while keeping the player and monster records live.
local function player_world(ctx, player, roll)
    local world = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to stealth awareness fixture actor so player-only branches execute on that entity.
    function world.player()
        return player
    end

    -- Clamp the requested AI draw to its bound while varying the awareness roll.
    function world.random(_, stream, maximum)
        harness.equal(stream, "ai", "awareness uses the AI RNG stream")
        return math.min(roll, maximum - 1)
    end

    return world
end

-- Stealth ego adds one pip after ring mail encumbrance.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.SKILLS, { entries = {} })

    local world = player_world(ctx, player, 99)

    harness.equal(stealth.score(world, player), 30,
        "untrained dexterity ten gives thirty stealth")

    records.grant_acquired(world, player, mutations.MUT_CAMOUFLAGE, 2)
    harness.equal(stealth.score(world, player), 130,
        "Camouflage grants fifty stealth per level")

    records.grant_acquired(world, player,
        mutations.MUT_THIN_SKELETAL_STRUCTURE, 1)
    harness.equal(stealth.score(world, player), 186,
        "thin skeletal structure grants a pip and raises dexterity")

    records.grant_acquired(world, player, mutations.MUT_GLOWING, 1)
    -- Backlighting is applied after additive mutation and equipment stealth modifiers.
    harness.equal(stealth.score(world, player), 74,
        "Glowing reduces the final stealth score to two fifths")

    local monster = ctx:create()
    ctx:add(monster, component.ACTOR, { kind_id = monsters.MONS_GOBLIN })

    local state = { behavior = "wander" }
    harness.equal(awareness.detects(world, monster, state, true), false,
        "a high awareness roll misses a camouflaged player")

    world = player_world(ctx, player, 0)
    harness.equal(awareness.detects(world, monster, state, true), true,
        "a low awareness roll detects a visible player")
    -- Awareness cannot use a successful roll without a valid line of sight.
    harness.equal(awareness.detects(world, monster, state, false), false,
        "walls prevent visual detection")

    records.grant_acquired(world, player, mutations.MUT_NO_STEALTH, 1)
    harness.equal(stealth.score(world, player), 0,
        "sacrificed stealth overrides other bonuses")
    harness.equal(awareness.detects(world, monster, state, true), true,
        "zero stealth always alerts visible monsters")

    local plain = ctx:create()
    ctx:add(plain, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(plain, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(plain, component.SKILLS, { entries = {} })

    world = player_world(ctx, plain, 99)

    local armour = ctx:create()
    ctx:add(armour, component.ITEM, {
        kind_id = items.ARM_RING_MAIL,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(armour, component.CARRIED_BY, { holder = plain })
    ctx:add(armour, component.EQUIPPED, { slot = "body" })

    harness.equal(stealth.score(world, plain), 0,
        "ring mail's quadratic encumbrance overwhelms low stealth")

    local mail = ctx:get(armour, component.ITEM)
    mail.ego = armour_egos.STEALTH
    ctx:set(armour, component.ITEM, mail)

    harness.equal(stealth.score(world, plain), 48,
        "stealth ego adds one pip after ring mail encumbrance")
end

return test
