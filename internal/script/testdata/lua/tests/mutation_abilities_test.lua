
local abilities = require("ids.abilities")
local component = require("constants.component")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local commands = require("policy.commands.abilities")
local ability_input = require("policy.input.abilities")
local catalog = require("policy.catalog")
local chaos = require("policy.abilities.word_of_chaos")
local cooldowns = require("policy.abilities.cooldowns")
local registry = require("policy.abilities.registry")
local records = require("policy.mutations.records")
local terrain = require("constants.terrain")
local monsters = require("ids.monsters")
local net = require("policy.combat.net")

local test = {}

-- Let innate ability policies read live ECS while map and RNG calls are scripted.
local function world_for(ctx, player)
    local world = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to abilities fixture actor so player-only branches execute on that entity.
    function world.player()
        return player
    end

    -- Define abilities fixture's traversable cells for movement and targeting checks.
    function world.walkable(_, _, x, y)
        return x >= 1 and x <= 12 and y >= 1 and y <= 12
    end

    -- Give the ordinary ability fixture floor terrain.
    function world.cell()
        return terrain.DNGN_FLOOR
    end

    -- Make abilities sight deterministic while leaving actor positions to the ECS fixture.
    function world.visible()
        return true
    end

    -- Expose abilities fixture occupant at the queried cell for collision or targeting.
    function world.actor_at()
        return nil
    end

    -- Use the highest bounded draw so ability fallback choices take their late branch.
    function world.random(_, _, bound)
        return bound - 1
    end

    -- Write ability relocation into the actor position component to test the chosen square.
    function world.move_actor(_, actor, level_id, x, y)
        ctx:set(actor, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    return world
end

-- Unowned innate abilities reject without spending time.
function test.run(ctx)
    local player = ctx:create()
    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 2,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
        total_xp = 10000,
    })
    ctx:add(player, component.HEALTH, {
        current = 50,
        max = 50,
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })

    local world = world_for(ctx, player)
    local unavailable = commands.prepare(world, player, {
        ability_id = abilities.HOP,
        dx = 4,
        dy = 0,
    })

    -- An unowned ability must fail before the action clock or cooldown changes.
    harness.truthy(unavailable.message,
        "unowned innate abilities reject without spending time")

    records.grant_acquired(world, player, mutations.MUT_HOP, 1)
    records.grant_acquired(world, player,
        mutations.MUT_HURL_DAMNATION, 1)
    records.grant_acquired(world, player,
        mutations.MUT_WORD_OF_CHAOS, 1)

    local listed = registry.available(world, player)
    harness.equal(#listed, 3,
        "all three innate mutation abilities appear in one list")

    local word_choice = ability_input.route({
        key = "c",
        options = listed,
    })
    harness.equal(word_choice.action, "confirm_ability",
        "Word of Chaos asks before affecting no visible enemies")

    local hop = commands.prepare(world, player, {
        ability_id = abilities.HOP,
        dx = 4,
        dy = 0,
    })
    harness.equal(hop.cost, 10,
        "valid Hop spends one normal action")
    harness.equal(hop.intent.ability_id, abilities.HOP,
        "the ability intent retains its named ID")

    local too_far = commands.prepare(world, player, {
        ability_id = abilities.HOP,
        dx = 5,
        dy = 0,
    })
    -- Range validation precedes the landing-cell search and its random draws.
    harness.truthy(too_far.message,
        "level-one Hop rejects a target beyond four cells")

    local damnation = commands.prepare(world, player, {
        ability_id = abilities.HURL_DAMNATION,
        dx = 6,
        dy = 0,
    })
    harness.equal(damnation.intent.ability_id,
        abilities.HURL_DAMNATION,
        "Hurl Damnation uses the same ability intent envelope")

    registry.resolve(world, player, hop.intent, 10)

    local landing = world:get(player, component.POSITION)
    -- A valid Hop spends time only after its destination has been resolved.
    harness.truthy(math.abs(landing.x - 6) <= 2 and
        math.abs(landing.y - 2) <= 2,
        "Hop lands near the selected target")

    local cooldown = world:get(player, component.ABILITY_COOLDOWNS)
    harness.truthy(cooldown.hop_aut > 0,
        "Hop starts its source cooldown")

    local remaining = cooldown.hop_aut
    cooldowns.tick(world, player, 10)
    harness.equal(world:get(player, component.ABILITY_COOLDOWNS).hop_aut,
        remaining - 10,
        "Hop cooldown decays by action time")

    local repeated = commands.prepare(world, player, {
        ability_id = abilities.HOP,
        dx = 1,
    })
    harness.truthy(repeated.message,
        "Hop cannot be used again during its cooldown")

    local rat = ctx:create()
    ctx:add(rat, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(rat, component.POSITION, {
        level_id = 1,
        x = 4,
        y = 4,
    })

    local recovery = world:get(player, component.ABILITY_COOLDOWNS)
    recovery.hop_aut = 0
    world:set(player, component.ABILITY_COOLDOWNS, recovery)
    world:add(player, component.CONSTRICTION, {
        by = rat,
        escape_attempts = 0,
    })

    local held_hop = commands.prepare(world, player, {
        ability_id = abilities.HOP,
        dx = 1,
    })
    harness.equal(held_hop.cost, 10,
        "constriction permits a timed Hop escape attempt")
    registry.resolve(world, player, held_hop.intent, 10)
    harness.falsy(world:has(player, component.CONSTRICTION),
        "successful Hop escape releases the constriction")

    local unsafe = setmetatable({}, { __index = world })

    -- Switch this cell to deep water to test an unsafe ability destination.
    function unsafe.cell()
        return terrain.DNGN_DEEP_WATER
    end

    local before_unsafe = world:get(player, component.POSITION)
    registry.resolve(unsafe, player, held_hop.intent, 10)
    local after_unsafe = world:get(player, component.POSITION)
    harness.equal(after_unsafe.x, before_unsafe.x,
        "Hop does not land in lethal deep water")
    harness.equal(after_unsafe.y, before_unsafe.y,
        "Hop keeps the player on safe terrain")

    chaos.ensnare(world, rat,
        catalog.get("monsters", monsters.MONS_RAT))
    harness.truthy(world:has(rat, component.HELD),
        "Word of Chaos ensnares through the net status")
    net.validate(world, rat, world:get(rat, component.POSITION))

    local shuffle_world = setmetatable({}, { __index = world })

    -- Force zero in the shuffle to pin the exact Word of Chaos permutation.
    function shuffle_world.random()
        return 0
    end

    local ordered = chaos.shuffle(shuffle_world,
        { "first", "second", "third" })
    harness.equal(table.concat(ordered, ","), "second,third,first",
        "Word targets use the source shuffle before status rolls")
end

return test
