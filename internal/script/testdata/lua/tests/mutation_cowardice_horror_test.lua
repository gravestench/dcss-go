local component = require("constants.component")
local catalog = require("policy.catalog")
local classes = require("constants.mutation_classes")
local death = require("policy.death")
local formulas = require("policy.character.formulas")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local species = require("ids.species")
local skills = require("ids.skills")
local spells = require("ids.spells")
local horror = require("policy.character.horror")
local power = require("policy.magic.power")
local records = require("policy.mutations.records")
local transition = require("policy.mutations.transition")
local slay = require("policy.combat.player_slay")
local save_status = require("policy.save.status")
local horror_system = require("systems.character_horror")

local test = {}

local function add_monster(ctx, kind_id, x, max_hp)
    local monster = ctx:create()
    local health = max_hp or 25

    ctx:add(monster, component.ACTOR, {
        kind_id = kind_id,
        speed = 10,
    })
    ctx:add(monster, component.HEALTH, {
        current = health,
        max = health,
    })
    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = x,
        y = 1,
    })

    return monster
end

local function visible_world(ctx, player)
    local world = setmetatable({}, { __index = ctx })

    function world.player()
        return player
    end

    function world.visible()
        return true
    end

    return world
end

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Cowardice test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
        total_xp = 0,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.SKILLS, {
        entries = {
            {
                id = skills.SK_HEXES,
                level = 5,
                points = formulas.skill_points_needed(5, 0),
            },
        },
    })
    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 20,
    })

    local world = visible_world(ctx, player)
    local spell = catalog.get("spells", spells.SPELL_CONFUSING_TOUCH)
    local first = add_monster(ctx, monsters.MONS_OGRE, 2)
    local second = add_monster(ctx, monsters.MONS_OGRE, 3)
    add_monster(ctx, monsters.MONS_ELDRITCH_TENTACLE, 4)

    horror_system.update(world, player)
    harness.equal(horror.penalty(world, player), 0,
        "ordinary characters have no horror penalty")
    harness.equal(power.cast(world, player, spell), 10,
        "trained Hexes power without horror")

    records.grant_acquired(ctx, player, mutations.MUT_COWARDICE, 1)
    horror_system.update(world, player)
    harness.equal(horror.penalty(world, player), 5,
        "two nasty monsters give five horror levels; tentacles do not count")
    harness.equal(slay.total(world, player), -5,
        "horror removes one point of slaying per level")
    harness.equal(horror.spell_power(1000, 5), 588,
        "five horror levels reduce centi spell power before stepdown")
    harness.equal(power.cast(world, player, spell), 5,
        "spell casting consumes the saved horror penalty")

    transition.remove(world, player, mutations.MUT_COWARDICE,
        classes.ACQUIRED)
    harness.equal(horror.penalty(world, player), 0,
        "losing Cowardice clears horror before the next turn")
    records.grant_acquired(ctx, player, mutations.MUT_COWARDICE, 1)
    horror_system.update(world, player)

    ctx:remove(second, component.HEALTH)
    horror_system.update(world, player)
    harness.equal(horror.penalty(world, player), 2,
        "one nasty monster leaves two horror levels")

    ctx:remove(first, component.HEALTH)
    local slime = catalog.get("monsters", monsters.MONS_ENDOPLASM)

    harness.equal(death.experience(slime, 44), 6,
        "the source XP boundary for a tough level-one monster")

    local first_slime = add_monster(ctx, monsters.MONS_ENDOPLASM, 5, 44)
    local second_slime = add_monster(ctx, monsters.MONS_ENDOPLASM, 6, 44)

    horror_system.update(world, player)
    harness.equal(horror.penalty(world, player), 1,
        "two six-XP monsters are tough at XL1")

    ctx:remove(first_slime, component.HEALTH)
    ctx:remove(second_slime, component.HEALTH)
    horror_system.update(world, player)
    harness.equal(horror.penalty(world, player), 0,
        "horror ends when the threatening monsters leave")

    local progress = ctx:get(player, component.PROGRESSION)
    progress.level = 15
    ctx:set(player, component.PROGRESSION, progress)

    local first_sphinx = add_monster(ctx, monsters.MONS_SPHINX, 5, 88)
    local second_sphinx = add_monster(ctx, monsters.MONS_SPHINX, 6, 88)

    horror_system.update(world, player)
    harness.equal(horror.penalty(world, player), 5,
        "XL15 horror uses source legacy XP for two Sphinxes")

    ctx:remove(first_sphinx, component.HEALTH)
    ctx:remove(second_sphinx, component.HEALTH)
    horror_system.update(world, player)

    ctx:add(player, component.HORROR, { penalty = -1 })
    harness.falsy(pcall(save_status.run, world),
        "restore rejects a negative horror penalty")
    ctx:remove(player, component.HORROR)

    records.delete(ctx, player, mutations.MUT_COWARDICE,
        classes.ACQUIRED, 1)
    ctx:add(player, component.HORROR, { penalty = 2 })
    harness.falsy(pcall(save_status.run, world),
        "restore rejects horror without Cowardice")
end

return test
