-- Stoke Flames' inferno keeps its owner and explodes through the ordinary
-- actor death phase. The blast uses the same Fire Storm profile as its spell.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local clouds = require("ids.clouds")
local component = require("constants.component")
local death = require("systems.actor_death")
local effects = require("policy.combat.monster_spells")
local expiry = require("systems.magic_summon_expiry")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local species = require("ids.species")
local jobs = require("ids.jobs")
local items = require("ids.items")
local spells = require("ids.spells")

local test = {}

-- A zero random draw takes the first free adjacent cell and chooses the
-- source radius-three branch, bringing the player into the explosion.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 7, 5, 100)
    local caster = fixture.actor(ctx, monsters.MONS_STOKER, 5, 5, 30)
    local game = fixture.context(ctx, player)
    local effect = effects.effect(spells.SPELL_STOKE_FLAMES)

    -- Fire Storm's player AC path reads the same starting combat state as a
    -- live Human Fighter, so this fixture supplies those production fields.
    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Inferno target",
        starting_weapon_id = items.WPN_UNARMED,
    })
    ctx:add(player, "core.attributes", {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, "core.skills", {
        entries = {},
    })
    ctx:add(player, "core.combat", {
        shield_blocks = 0,
    })

    function game:random()
        return 0
    end

    local plan = effect.plan(game, caster, player)

    harness.truthy(plan, "Stoke Flames has a self-target plan")
    effect.resolve(game, caster, player, nil, plan)

    local inferno

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local actor = ctx:get(entity, component.ACTOR)

        if actor.kind_id == monsters.MONS_CREEPING_INFERNO then
            inferno = entity
        end
    end

    harness.truthy(inferno, "the cast creates a physical inferno")

    local summon = ctx:get(inferno, component.SUMMON)

    harness.equal(summon.owner, caster, "inferno retains its caster")
    harness.equal(summon.source_id, spells.SPELL_STOKE_FLAMES,
        "inferno retains its spell source")
    harness.truthy(summon.expires_aut > 0,
        "source abjuration gives a saved expiry")

    local before = ctx:get(player, component.HEALTH).current
    local health = ctx:get(inferno, component.HEALTH)

    health.current = 0
    ctx:set(inferno, component.HEALTH, health)

    -- The shared expiry phase must leave an HP-killed inferno intact for the
    -- actor death hook; ordinary summons disappear before that phase.
    expiry.update(game, player)

    harness.truthy(ctx:has(inferno, component.ACTOR),
        "expiry leaves dead inferno for its explosion")

    death.update(game)

    harness.falsy(ctx:has(inferno, component.ACTOR),
        "the death phase consumes the inferno")
    harness.truthy(ctx:get(player, component.HEALTH).current < before,
        "its death blast damages the nearby player")

    local fire = 0

    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local cloud = ctx:get(entity, component.WORLD_CLOUD)

        if cloud.kind_id == clouds.CLOUD_FIRE then
            fire = fire + 1
        end
    end

    harness.truthy(fire > 0, "Fire Storm leaves saved fire clouds")

    -- Death consumes the inferno entity. Running the same phase again must
    -- neither damage the player twice nor create another cloud ring.
    local after_death = ctx:get(player, component.HEALTH).current

    death.update(game)

    harness.equal(ctx:get(player, component.HEALTH).current,
        after_death, "inferno death damage runs once")

    local remaining_fire = 0

    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local cloud = ctx:get(entity, component.WORLD_CLOUD)

        if cloud.kind_id == clouds.CLOUD_FIRE then
            remaining_fire = remaining_fire + 1
        end
    end

    harness.equal(remaining_fire, fire,
        "a second death phase leaves the same cloud ring")

    local profile = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_FIRE_STORM)

    harness.truthy(profile.monster_damage,
        "inferno shares the registered monster Fire Storm dice")
end

return test
