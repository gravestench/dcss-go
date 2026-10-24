-- These checks use the production player schema and combat skill reader.
-- Okawaru changes effective skill, never the earned skill-point record.
local abilities = require("ids.abilities")
local component = require("constants.component")
local fighter = require("policy.combat.fighter")
local fixture = require("tests.monster_ally_support_fixture")
local formulas = require("policy.character.formulas")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local rage = require("policy.character.rage")
local skills = require("ids.skills")
local species = require("ids.species")
local status = require("policy.religion.okawaru.status")
local eligibility = require("policy.world.arena.eligibility")

local test = {}

-- A real player component lets both the ability and combat paths read the
-- same skill points; only the test's RNG is fixed for duration assertions.
local function worshipper(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)
    local level = 5
    local points = formulas.skill_points_needed(level, 0) + 1

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.PROGRESSION, { level = 1 })
    ctx:add(player, component.SKILLS, {
        entries = {
            { id = skills.SK_FIGHTING, level = level, points = points },
            { id = skills.SK_SPELLCASTING, level = level, points = points },
            { id = skills.SK_INVOCATIONS, level = level, points = points },
        },
    })
    ctx:add(player, component.MAGIC, {
        current = 20,
        max = 20,
    })
    ctx:add(player, component.HEALTH, {
        current = 30,
        max = 30,
    })
    ctx:add(player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.OKAWARU,
        piety = piety.breakpoint(5),
        penance = {},
    })

    function game:random(_, bound)
        return bound - 1
    end

    return game, player
end

-- Heroism adds five capped levels through Unarmed Combat, while magic
-- training and saved points stay where the player earned them.
local function heroic_skills(game, player)
    local ordinary = fighter.skill(game, skills.SK_FIGHTING, 100)
    local magical = fighter.skill(game, skills.SK_SPELLCASTING, 100)
    local invocations = fighter.skill(game, skills.SK_INVOCATIONS, 100)
    local evocations = fighter.skill(game, skills.SK_EVOCATIONS, 100)
    local saved = game:get(player, component.SKILLS)

    status.invoke(game, player, "heroism")

    harness.equal(fighter.skill(game, skills.SK_FIGHTING, 100),
        ordinary + 500)
    harness.equal(fighter.skill(game, skills.SK_SPELLCASTING, 100),
        magical)
    harness.equal(fighter.skill(game, skills.SK_INVOCATIONS, 100),
        invocations)
    harness.equal(fighter.skill(game, skills.SK_EVOCATIONS, 100),
        evocations)
    harness.equal(game:get(player, component.SKILLS).entries[1].points,
        saved.entries[1].points)
    local identity = game:get(player, component.PLAYER)

    identity.species_id = species.SP_FELID
    game:set(player, component.PLAYER, identity)
    harness.equal(fighter.skill(game, skills.SK_ARMOUR, 100), 0)
    harness.equal(fighter.skill_level(game, skills.SK_ARMOUR), 0)
    identity.species_id = species.SP_HUMAN
    game:set(player, component.PLAYER, identity)
    harness.truthy(status.active(game, player, "heroism"))
    local first_clock = game:get(player,
        component.RELIGION_OKAWARU_STATUS).heroism_aut

    status.invoke(game, player, "heroism")

    local renewed_clock = game:get(player,
        component.RELIGION_OKAWARU_STATUS).heroism_aut

    harness.truthy(renewed_clock > first_clock)
    status.tick(game, player, renewed_clock)
    harness.falsy(status.active(game, player, "heroism"))
    status.invoke(game, player, "heroism")
    status.clear(game, player)
    harness.equal(fighter.skill(game, skills.SK_FIGHTING, 100),
        ordinary)
end

-- The registered power uses the source rank and MP gate before any turn,
-- then shares the same saved status state that combat reads.
function test.run(ctx)
    local game, player = worshipper(ctx)
    local heroism = registry.get(abilities.OKAWARU_HEROISM)
    local finesse = registry.get(abilities.OKAWARU_FINESSE)

    harness.truthy(heroism)
    harness.truthy(finesse)
    harness.truthy(heroism.available(game, player))
    harness.truthy(finesse.available(game, player))
    heroic_skills(game, player)

    status.invoke(game, player, "finesse")
    harness.truthy(status.active(game, player, "finesse"))
    harness.truthy(rage.begin(game, player, "religion", true, false))
    harness.falsy(status.active(game, player, "finesse"))

    local magic = game:get(player, component.MAGIC)

    magic.current = 1
    game:set(player, component.MAGIC, magic)
    harness.truthy(heroism.prepare(game, player))

    -- The same live hostile Ogre is worthy while an empty or allied cell
    -- cancels freely; no synthetic monster definition is needed here.
    local ogre = fixture.actor(ctx, monsters.MONS_OGRE, 8, 7, 100)
    local target, rejection = eligibility.target(game, player, 1, 0)

    harness.equal(target, ogre)
    harness.falsy(rejection)
    harness.truthy(eligibility.target(game, player, 2, 0) == nil)
end

return test
