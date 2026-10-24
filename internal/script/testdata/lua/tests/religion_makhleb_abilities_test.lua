-- These checks command the same registered powers that the game menu uses.
-- The fixture supplies only a sparse grid; actors and costs use live ECS.
local abilities = require("ids.abilities")
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local commands = require("policy.commands.abilities")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local mutation_classes = require("constants.mutation_classes")
local records = require("policy.mutations.records")
local piety = require("policy.religion.piety")
local projectile = require("policy.magic.effects.zaps.projectile")
local registry = require("policy.abilities.registry")
local roster = require("policy.religion.makhleb.roster")
local saved_summons = require("policy.save.summons")
local selections = require("policy.religion.makhleb.destruction")
local species = require("ids.species")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")
local will = require("policy.magic.effects.zaps.will")

local test = {}

-- Start with a healthy worshipper whose rank can be changed without
-- rebuilding component schemas for each source unlock threshold.
local function worshipper(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, { level = 12 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 20,
        y = 20,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.HEALTH, {
        current = 40,
        max = 40,
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.MAKHLEB,
        piety = piety.breakpoint(1),
        penance = {},
    })

    function game:random(_, bound)
        return bound - 1
    end

    return game, player
end

-- Each rank is a live condition, and penance hides powers even if the
-- worshipper keeps old piety in the saved worship component.
local function ranks(game, player)
    local ids = {
        abilities.MAKHLEB_MINOR_DESTRUCTION,
        abilities.MAKHLEB_LESSER_SERVANT,
        abilities.MAKHLEB_MAJOR_DESTRUCTION,
        abilities.MAKHLEB_GREATER_SERVANT,
    }
    local worship = game:get(player, component.RELIGION_WORSHIP)

    for index, id in ipairs(ids) do
        local definition = registry.get(id)

        harness.truthy(definition, id)
        harness.falsy(registry.usable_now(game, player, definition))
        worship.piety = piety.breakpoint(index + 1)
        game:set(player, component.RELIGION_WORSHIP, worship)
        harness.truthy(registry.usable_now(game, player, definition))
    end

    worship.penance[gods.MAKHLEB] = 1
    game:set(player, component.RELIGION_WORSHIP, worship)

    for _, id in ipairs(ids) do
        harness.falsy(registry.usable_now(game, player,
            registry.get(id)))
    end

    worship.penance[gods.MAKHLEB] = 0
    worship.piety = 200
    game:set(player, component.RELIGION_WORSHIP, worship)

    records.grant_acquired(game, player, mutations.MUT_NO_LOVE, 1)
    harness.falsy(registry.usable_now(game, player,
        registry.get(abilities.MAKHLEB_LESSER_SERVANT)))
    harness.falsy(registry.usable_now(game, player,
        registry.get(abilities.MAKHLEB_GREATER_SERVANT)))
    records.delete(game, player, mutations.MUT_NO_LOVE,
        mutation_classes.ACQUIRED, 1)
end

-- Source failure turns a servant against its summoner but still commits
-- fixed HP and rolled piety; successful selection produces a friendly one.
local function servants(game, player)
    local lesser = registry.get(abilities.MAKHLEB_LESSER_SERVANT)
    local before_hp = game:get(player, component.HEALTH).current
    local before_piety = game:get(player,
        component.RELIGION_WORSHIP).piety

    lesser.resolve(game, player)

    local summons = game:query({ component.SUMMON })
    local creature = summons[#summons]
    local state = game:get(creature, component.SUMMON)
    local friendly_creature = creature

    harness.truthy(creature)
    harness.equal(state.owner, player)
    harness.equal(state.source_category, categories.GODS)
    harness.equal(state.source_id, gods.MAKHLEB)
    harness.equal(state.attitude, attitudes.FRIENDLY)
    harness.truthy(state.expires_aut > 0)
    harness.truthy(roster.contains(game:get(creature,
        component.ACTOR).kind_id, "lesser"))

    local saved_ok, saved_error = pcall(saved_summons.validate, game,
        creature, game:get(creature, component.ACTOR),
        game:get(creature, component.POSITION),
        game:get(creature, component.AI), state, 0)

    harness.truthy(saved_ok,
        "friendly Makhleb servant must restore: " ..
            tostring(saved_error))
    harness.equal(game:get(player, component.HEALTH).current,
        before_hp - 4)
    harness.truthy(game:get(player,
        component.RELIGION_WORSHIP).piety < before_piety)

    function game:random(_, _)
        return 0
    end

    local greater = registry.get(abilities.MAKHLEB_GREATER_SERVANT)
    local hp = game:get(player, component.HEALTH).current

    greater.resolve(game, player)
    summons = game:query({ component.SUMMON })
    creature = summons[#summons]
    state = game:get(creature, component.SUMMON)
    harness.equal(state.attitude, attitudes.HOSTILE)
    harness.truthy(roster.contains(game:get(creature,
        component.ACTOR).kind_id, "greater"))
    saved_ok, saved_error = pcall(saved_summons.validate, game,
        creature, game:get(creature, component.ACTOR),
        game:get(creature, component.POSITION),
        game:get(creature, component.AI), state, 0)
    harness.truthy(saved_ok,
        "hostile Makhleb servant must restore: " ..
            tostring(saved_error))

    local actor = game:get(creature, component.ACTOR)
    local legal_kind = actor.kind_id

    actor.kind_id = monsters.MONS_OGRE
    game:set(creature, component.ACTOR, actor)
    saved_ok = pcall(saved_summons.validate, game,
        creature, actor,
        game:get(creature, component.POSITION),
        game:get(creature, component.AI), state, 0)
    harness.falsy(saved_ok,
        "an invented Makhleb demon must not restore")
    actor.kind_id = legal_kind
    game:set(creature, component.ACTOR, actor)

    local friendly_state = game:get(friendly_creature,
        component.SUMMON)
    local finite_deadline = friendly_state.expires_aut

    friendly_state.expires_aut = 0
    game:set(friendly_creature, component.SUMMON, friendly_state)
    saved_ok = pcall(saved_summons.validate, game,
        friendly_creature,
        game:get(friendly_creature, component.ACTOR),
        game:get(friendly_creature, component.POSITION),
        game:get(friendly_creature, component.AI),
        friendly_state, 0)
    harness.falsy(saved_ok,
        "a friendly servant cannot claim permanent wrath expiry")
    friendly_state.expires_aut = finite_deadline
    game:set(friendly_creature, component.SUMMON, friendly_state)
    harness.equal(game:get(player, component.HEALTH).current, hp - 10)

    -- A successful invocation with no open adjacent cell still pays its
    -- source costs but creates no fabricated creature.
    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(20 + dx) .. ":" .. (20 + dy)] = true
            end
        end
    end

    function game:random(_, bound)
        return bound - 1
    end

    local count = #game:query({ component.SUMMON })
    local blocked_hp = game:get(player, component.HEALTH).current
    local blocked_piety = game:get(player,
        component.RELIGION_WORSHIP).piety

    lesser.resolve(game, player)
    harness.equal(#game:query({ component.SUMMON }), count)
    harness.equal(game:get(player, component.HEALTH).current,
        blocked_hp - 4)
    harness.truthy(game:get(player,
        component.RELIGION_WORSHIP).piety < blocked_piety)
    game.walls = {}
end

-- The targeting prompt rejects zero direction and an unaffordable HP
-- cost without advancing the ability system or altering the player.
local function aimed(game, player)
    local id = abilities.MAKHLEB_MINOR_DESTRUCTION

    for _, tier in ipairs({ "minor", "major" }) do
        for _, zap_id in ipairs(selections[tier]) do
            harness.truthy(projectile.specs[zap_id], zap_id)
        end
    end

    local acid = projectile.specs[zaps.ZAP_BREATHE_ACID]

    harness.equal(acid.cap, 50)
    harness.equal(acid.damage.count, 5)
    harness.equal(acid.damage.base, 4)

    harness.truthy(commands.prepare(game, player, {
        ability_id = id,
    }).message)

    -- A friendly servant on the ray makes refusal free, even though the
    -- source failure and power rolls are consumed before its tracer abort.
    local ally = game:query({ component.SUMMON })[1]
    local location = game:get(ally, component.POSITION)

    harness.truthy(commands.prepare(game, player, {
        ability_id = id,
        dx = location.x - 20,
        dy = location.y - 20,
    }).message)

    function game:random(_, bound)
        return bound - 1
    end

    local health_before = game:get(player, component.HEALTH).current
    local piety_before = game:get(player,
        component.RELIGION_WORSHIP).piety

    harness.truthy(commands.prepare(game, player, {
        ability_id = id,
        dx = 1,
        dy = 0,
    }).intent)
    registry.get(id).resolve(game, player, { dx = 1, dy = 0 })
    harness.equal(game:get(player, component.HEALTH).current,
        health_before - 1)
    harness.equal(game:get(player,
        component.RELIGION_WORSHIP).piety, piety_before)

    registry.get(abilities.MAKHLEB_MAJOR_DESTRUCTION).resolve(
        game, player, { dx = 1, dy = 0 })
    harness.equal(game:get(player, component.HEALTH).current,
        health_before - 7)
    harness.equal(game:get(player,
        component.RELIGION_WORSHIP).piety, piety_before - 1)

    local health = game:get(player, component.HEALTH)

    health.current = 1
    game:set(player, component.HEALTH, health)
    harness.truthy(commands.prepare(game, player, {
        ability_id = id,
        dx = 1,
    }).message)
end

-- Pain is an enchantment in the source: it checks will and negative
-- energy resistance instead of making a projectile EV/AC contact roll.
local function pain_contact(game, player)
    local spec = projectile.specs[spells.SPELL_PAIN]

    harness.truthy(spec.enchantment)

    local target = fixture.actor(game.base, monsters.MONS_ORC,
        21, 20, 60)
    local before = game:get(target, component.HEALTH).current

    function game:random(_, bound)
        return bound - 1
    end

    local original_resists = will.resists
    local enchant_power

    -- Capture the actual will-check argument; a guaranteed high roll would
    -- hide a source power-scaling error while still making damage pass.
    function will.resists(_, _, power)
        enchant_power = power
        return false
    end

    projectile.fire(game, player, { dx = 1, dy = 0 },
        nil, spec, 100, 5)
    will.resists = original_resists

    harness.equal(enchant_power, 350)
    harness.truthy(game:get(target, component.HEALTH).current < before)
end

-- One test entry makes rank, summon, and aim behavior exercise the same
-- production registry and live worship component.
function test.run(ctx)
    local game, player = worshipper(ctx)

    ranks(game, player)
    servants(game, player)
    pain_contact(game, player)
    aimed(game, player)
end

return test
