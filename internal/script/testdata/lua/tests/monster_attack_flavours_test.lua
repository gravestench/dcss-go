-- A generated Pan lord's saved melee flavour must change the defender's
-- real actor state after contact. Source: melee-attack.cc attack flavour
-- handling; misses must never trigger a secondary effect.
local actions = require("policy.combat.melee_actions")
local artefacts = require("ids.artefacts")
local catalog = require("policy.catalog")
local component = require("constants.component")
local jobs = require("ids.jobs")
local items = require("ids.items")
local pan_lord = require("policy.population.pan_lord")
local fixture = require("tests.monster_ally_support_fixture")
local form_ids = require("constants.form_ids")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local species = require("ids.species")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")
local traits = require("constants.pan_lord_traits")

local test = {}

-- Read the same component that character attributes and save/restore use.
-- Zero draws trigger the source's rare first gate and its recovery timer.
local function check_stat_drains(ctx)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 12, 12, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 13, 12, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)

    -- Force each proc and recovery draw to its first source outcome.
    function game:random(_, bound)
        harness.truthy(bound > 0, "all flavour draws have positive bounds")

        return 0
    end

    local ok, flavours = pcall(require,
        "policy.combat.monster_attack_flavours")

    harness.truthy(ok, "monster attack flavour policy loads")

    local cases = {
        {
            flavour = traits.drain_strength,
            stat = stats.STRENGTH,
        },

        {
            flavour = traits.drain_intelligence,
            stat = stats.INTELLIGENCE,
        },

        {
            flavour = traits.drain_dexterity,
            stat = stats.DEXTERITY,
        },
    }

    for _, case in ipairs(cases) do
        local hit = {
            kind = "hit",
            attacker = lord,
            defender = player,
            hit_dice = 20,
        }

        flavours.apply(game, case.flavour, hit)

        harness.equal(stat_loss.amount(game, player, case.stat), 1,
            "confirmed " .. case.flavour .. " drains its named stat")
    end

    flavours.apply(game, traits.drain_strength, {
        kind = "miss",
        attacker = lord,
        defender = player,
        hit_dice = 20,
    })

    harness.equal(stat_loss.amount(game, player, stats.STRENGTH), 1,
        "a missed strike does not drain a stat")
end

-- A saved generated profile must reach the same policy through an actual
-- monster action. This catches a dispatcher that works only when called by
-- a test or one that forgets to project the actor's generated flavour.
local function check_live_contact(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 31, 30, 1000)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 30, 30, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Pan melee test",
    })

    ctx:add(player, component.PROGRESSION, {
        level = 27,
    })

    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })

    ctx:add(player, component.SKILLS, {
        entries = {},
    })

    ctx:add(player, component.COMBAT, {
        shield_blocks = 0,
    })

    local game = fixture.context(ctx, player)

    -- Keep profile generation deterministic before the live hit test.
    function game:random(_, bound)
        return bound - 1
    end

    local generated = pan_lord.roll(game, false)

    generated.flavour_id = traits.drain_strength
    ctx:add(lord, component.PANDEMONIUM_LORD, generated)

    -- Normal contact draws stay high enough to hit; the named stat-drain
    -- chance is forced low only after the profile has been generated.
    function game:random(stream, bound)
        if stream == "melee" and bound == 20 then
            return 0
        end

        return bound - 1
    end

    actions.monster(game, lord)

    harness.equal(stat_loss.amount(game, player, stats.STRENGTH), 1,
        "live Pan lord hit applies its saved stat-drain flavour")

    local messages = {}

    -- Capture the live effect message to check its attacker identity.
    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    generated.flavour_id = traits.corrode
    ctx:set(lord, component.PANDEMONIUM_LORD, generated)
    actions.monster(game, lord)

    harness.truthy(ctx:has(player, component.CORROSION),
        "live Pan lord corrosion reaches the player")

    local named = false

    for _, message in ipairs(messages) do
        if message:find("pandemonium lord", 1, true) and
            message:find("corrodes you", 1, true) then
            named = true
        end
    end

    harness.truthy(named,
        "live corrosion message names its generated attacker")
end

-- The other generated flavours must call the same saved status, HP, and
-- movement owners that ordinary spells and attacks use. These independent
-- actors keep one effect from masking a later assertion.
local function check_other_flavours(ctx)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 40, 40, 1000)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 41, 40, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Pan flavour target",
    })

    local game = fixture.context(ctx, player)
    local messages = {}

    -- Force the source proc branches and deterministic status lengths.
    function game:random(_, bound)
        harness.truthy(bound > 0, "flavour draw bound")

        return 0
    end

    -- Record trample feedback before later statuses add messages.
    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    local flavours = require("policy.combat.monster_attack_flavours")
    local hit = {
        kind = "hit",
        attacker = lord,
        attacker_name = "pandemonium lord",
        defender = player,
        hit_dice = 20,
        damage_done = 4,
    }

    flavours.apply(game, traits.trample, hit)

    harness.equal(ctx:get(player, component.POSITION).x, 42,
        "trample pushes the defender one cell away")
    harness.equal(ctx:get(lord, component.POSITION).x, 41,
        "trampling attacker follows into the old defender cell")
    harness.equal(messages[#messages], "You stumble backwards!",
        "trample reports its displacement to the player")

    local before = ctx:get(player, component.HEALTH).current

    flavours.apply(game, traits.drown, hit)

    harness.equal(ctx:get(player, component.HEALTH).current, before - 15,
        "drowning adds source HD-based water damage")

    flavours.apply(game, traits.corrode, hit)
    harness.truthy(ctx:has(player, component.CORROSION),
        "corrode adds saved player equipment corrosion")

    flavours.apply(game, traits.drain_speed, hit)
    harness.truthy(ctx:has(player, component.PLAYER_SLOW),
        "drain speed adds saved player slow")

    local previous_random = game.random

    -- Verify the Weakness duration draw stays on the melee stream.
    function game:random(stream, bound)
        if bound == 15 then
            harness.equal(stream, streams.MELEE,
                "melee weakness duration uses the melee stream")
        end

        return 0
    end

    flavours.apply(game, traits.weakness, hit)
    game.random = previous_random

    harness.truthy(ctx:has(player, component.PLAYER_WEAKNESS),
        "weakness adds saved player weakness")

    flavours.apply(game, traits.ensnare, hit)
    harness.truthy(ctx:has(player, component.TRAP_HELD),
        "ensnare adds a saved web hold")
end

-- Source trample cannot move a player into solid terrain. The layout
-- service must reject the destination before either actor changes cells.
local function check_blocked_trample(ctx)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 50, 50, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 51, 50, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)

    game.walls["52:50"] = true

    -- Force the shove chance so only the blocked cell decides movement.
    function game:random(_, bound)
        return 0
    end

    require("policy.combat.monster_attack_flavours").apply(game,
        traits.trample, {
            kind = "hit",
            attacker = lord,
            defender = player,
            hit_dice = 20,
        })

    harness.equal(ctx:get(player, component.POSITION).x, 51,
        "a wall prevents the trample push")
    harness.equal(ctx:get(lord, component.POSITION).x, 50,
        "a failed trample leaves the attacker in place")
end

-- Rooted forms cannot be knocked back, and a dead actor cannot acquire
-- a post-hit status or move after the ordinary physical strike kills it.
local function check_ineligible_targets(ctx)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 55, 55, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 56, 55, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    ctx:add(player, component.PLAYER_FORM, {
        form_id = form_ids.TREE,
        remaining_aut = 100,
    })

    local game = fixture.context(ctx, player)

    -- Force contact so rooted form, then death, is the decisive guard.
    function game:random(_, bound)
        return 0
    end

    local flavours = require("policy.combat.monster_attack_flavours")
    local hit = {
        kind = "hit",
        attacker = lord,
        defender = player,
        hit_dice = 20,
    }

    flavours.apply(game, traits.trample, hit)

    harness.equal(ctx:get(player, component.POSITION).x, 56,
        "tree form cannot be trampled")

    ctx:set(player, component.HEALTH, {
        current = 0,
        max = 100,
    })

    flavours.apply(game, traits.weakness, hit)
    harness.falsy(ctx:has(player, component.PLAYER_WEAKNESS),
        "a dead defender does not gain an attack status")
end

-- The source player's Mountain Boots prevent dislodging even when a
-- successful trample has open floor behind the defender.
local function check_mountain_boots(ctx)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 70, 70, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 71, 70, 100)
    local boots = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    ctx:add(boots, component.ITEM, {
        kind_id = items.ARM_BOOTS,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })

    ctx:add(boots, component.CARRIED_BY, {
        holder = player,
    })

    ctx:add(boots, component.EQUIPPED, {
        slot = "boots",
    })

    ctx:add(boots, component.ITEM_ARTEFACT, {
        unique_id = artefacts.UNRAND_MOUNTAIN_BOOTS,
    })

    local game = fixture.context(ctx, player)

    -- Force a shove attempt against the equipped artefact immunity.
    function game:random(_, bound)
        return 0
    end

    require("policy.combat.monster_attack_flavours").apply(game,
        traits.trample, {
            kind = "hit",
            attacker = lord,
            defender = player,
            hit_dice = 20,
        })

    harness.equal(ctx:get(player, component.POSITION).x, 71,
        "worn Mountain Boots prevent trampling")
end

-- Source actor::drain_stat is a no-op for monsters, while direct speed
-- drain grants the selected 5-turn Slow instead of rerolling spell duration.
local function check_monster_targets(ctx)
    local observer = fixture.actor(ctx, monsters.MONS_HUMAN, 60, 60, 100)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 62, 60, 100)
    local target = fixture.actor(ctx, monsters.MONS_RAT, 63, 60, 100)

    ctx:add(observer, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, observer)

    -- Select the minimum direct Slow strength for the monster target.
    function game:random(_, bound)
        return 0
    end

    local flavours = require("policy.combat.monster_attack_flavours")
    local hit = {
        kind = "hit",
        attacker = lord,
        attacker_name = "pandemonium lord",
        defender = target,
        defender_definition = catalog.get("monsters", monsters.MONS_RAT),
        hit_dice = 20,
        damage_done = 4,
    }

    flavours.apply(game, traits.drain_strength, hit)
    harness.falsy(ctx:has(target, component.STAT_LOSS),
        "monsters have no drainable player attributes")

    flavours.apply(game, traits.drain_speed, hit)
    harness.equal(ctx:get(target,
        component.PROJECTILE_SLOW).remaining_aut, 50,
        "monster Slow uses the rolled five-turn attack strength")

    flavours.apply(game, traits.corrode, hit)
    harness.truthy(ctx:get(target,
        component.MONSTER_ENCHANT).corrosion_aut > 0,
        "monster corrosion uses its saved enchantment")

    flavours.apply(game, traits.weakness, hit)
    harness.truthy(ctx:get(target,
        component.MONSTER_ENFEEBLE).weak_aut > 0,
        "monster weakness uses its saved status")

    local draws = 0

    -- A Large lord always shoves a Tiny rat, so source x_chance_in_y
    -- returns before spending a saved RNG draw.
    function game:random(_, bound)
        draws = draws + 1

        return 0
    end

    flavours.apply(game, traits.trample, hit)

    harness.equal(draws, 0,
        "a certain size contest does not advance melee RNG")
    harness.equal(ctx:get(target, component.POSITION).x, 64,
        "certain trample still moves its tiny target")
end

-- All cases use registered schemas and the normal combat and stat owners.
function test.run(ctx)
    check_stat_drains(ctx)
    check_live_contact(ctx)
    check_other_flavours(ctx)
    check_blocked_trample(ctx)
    check_ineligible_targets(ctx)
    check_mountain_boots(ctx)
    check_monster_targets(ctx)
end

return test
