-- Exercise Fedhas through the production ability registry and summon
-- schemas. The sparse grid only replaces level storage, not plant rules.
local abilities = require("ids.abilities")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local piety = require("policy.religion.piety")
local plants = require("policy.religion.fedhas.active_plants")
local passage = require("policy.religion.fedhas.pass_through")
local formulas = require("policy.character.formulas")
local registry = require("policy.abilities.registry")
local saved_summons = require("policy.save.summons")
local species = require("ids.species")
local skills = require("ids.skills")
local terrain = require("constants.terrain")

local test = {}

-- Build an ordinary worshipper so rank and MP checks read real ECS state.
local function worshipper(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 20,
        y = 20,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.MAGIC, {
        current = 40,
        max = 40,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.FEDHAS,
        piety = 200,
        penance = {},
    })

    -- Maximal rolls avoid invocation failure. Other draws still use the
    -- production call sites and can change source plant selection.
    function game:random(_, bound)
        return bound - 1
    end

    function game:marker_property()
        return nil
    end

    function game:walkable(_, x, y)
        local feature = self:cell(1, x, y)

        return feature == terrain.DNGN_FLOOR
    end

    return game, player
end

-- The saved summon must still satisfy the production restore validator.
local function check_plant(game, player, entity, kind_id)
    harness.truthy(entity)

    local actor = game:get(entity, component.ACTOR)
    local state = game:get(entity, component.SUMMON)

    harness.equal(actor.kind_id, kind_id)
    harness.equal(state.owner, player)
    harness.equal(state.source_category, categories.GODS)
    harness.equal(state.source_id, gods.FEDHAS)
    harness.equal(state.attitude, attitudes.FRIENDLY)
    harness.truthy(state.expires_aut > 0)

    local valid, problem = pcall(saved_summons.validate, game,
        entity, actor, game:get(entity, component.POSITION),
        game:get(entity, component.AI), state, 0)

    harness.truthy(valid, tostring(problem))

    actor.kind_id = monsters.MONS_OGRE
    game:set(entity, component.ACTOR, actor)
    valid = pcall(saved_summons.validate, game,
        entity, actor, game:get(entity, component.POSITION),
        game:get(entity, component.AI), state, 0)
    harness.falsy(valid,
        "a different monster cannot claim a Fedhas invocation")
    actor.kind_id = kind_id
    game:set(entity, component.ACTOR, actor)
end

-- Each menu entry appears at its source star rank, and penance suppresses
-- all four without mutating the ability registry.
local function check_ranks(game, player)
    local ids = {
        abilities.FEDHAS_WALL_OF_BRIARS,
        abilities.FEDHAS_GROW_BALLISTOMYCETE,
        abilities.FEDHAS_OVERGROW,
        abilities.FEDHAS_GROW_OKLOB,
    }
    local worship = game:get(player, component.RELIGION_WORSHIP)

    for index, id in ipairs(ids) do
        harness.truthy(id, "Fedhas ability ID is missing")
        local power = registry.get(id)

        harness.truthy(power, id)
        worship.piety = piety.breakpoint(index + 1) - 1
        game:set(player, component.RELIGION_WORSHIP, worship)
        harness.falsy(power.available(game, player))
        worship.piety = piety.breakpoint(index + 1)
        game:set(player, component.RELIGION_WORSHIP, worship)
        harness.truthy(power.available(game, player))
    end

    worship.piety = 200
    worship.penance[gods.FEDHAS] = 1
    game:set(player, component.RELIGION_WORSHIP, worship)

    for _, id in ipairs(ids) do
        harness.falsy(registry.get(id).available(game, player))
    end

    worship.penance[gods.FEDHAS] = 0
    game:set(player, component.RELIGION_WORSHIP, worship)
end

-- Wall of Briars is centered on the worshipper and leaves occupied cells
-- untouched. Both aimed growers place exactly the selected plant.
local function check_summons(game, player)
    local wall = registry.get(abilities.FEDHAS_WALL_OF_BRIARS)
    local before = #game:query({ component.SUMMON })

    harness.falsy(wall.prepare(game, player))
    wall.resolve(game, player)

    local summoned = game:query({ component.SUMMON })

    harness.truthy(#summoned > before)

    for _, entity in ipairs(summoned) do
        check_plant(game, player, entity, monsters.MONS_BRIAR_PATCH)
    end

    harness.truthy(wall.prepare(game, player),
        "an existing briar ring should block a second wall")

    local ballisto = registry.get(abilities.FEDHAS_GROW_BALLISTOMYCETE)
    local oklob = registry.get(abilities.FEDHAS_GROW_OKLOB)

    harness.truthy(ballisto.prepare(game, player, { dx = 3, dy = 0 }))
    harness.falsy(oklob.prepare(game, player, { dx = 0, dy = 0 }))
    harness.falsy(ballisto.prepare(game, player, { dx = 2, dy = 0 }))
    ballisto.resolve(game, player, { dx = 2, dy = 0 })

    local creature = game:actor_at(1, 22, 20)

    check_plant(game, player, creature, monsters.MONS_BALLISTOMYCETE)
    harness.truthy(oklob.prepare(game, player, { dx = 2, dy = 0 }))
    harness.falsy(oklob.prepare(game, player, { dx = 0, dy = 2 }))
    oklob.resolve(game, player, { dx = 0, dy = 2 })
    check_plant(game, player, game:actor_at(1, 20, 22),
        monsters.MONS_OKLOB_PLANT)

end

-- Source excludes hostile Oklobs by species, including the sapling kind.
-- A different hostile stationary plant remains passable under the passive.
local function check_passage(ctx)
    local game, player = worshipper(ctx)
    local sapling = ctx:create()

    ctx:add(sapling, component.ACTOR, {
        kind_id = monsters.MONS_OKLOB_SAPLING,
        speed = 10,
    })
    game:place_actor(sapling, 1, 30, 20)

    harness.falsy(passage.at(game, player, 1, 30, 20))

    local actor = game:get(sapling, component.ACTOR)
    actor.kind_id = monsters.MONS_BALLISTOMYCETE
    game:set(sapling, component.ACTOR, actor)

    harness.equal(passage.at(game, player, 1, 30, 20), sapling)
end

-- Fractional Invocations must use source stochastic rounding twice, HD
-- first and duration second, rather than truncating before either draw.
local function check_fractional_skill(ctx)
    local game, player = worshipper(ctx)
    local human = catalog.get(categories.SPECIES, species.SP_HUMAN)
    local aptitude = human.aptitudes[skills.SK_INVOCATIONS].value
    local halfway = math.floor(formulas.skill_points_needed(1,
        aptitude) / 2)

    game:set(player, component.SKILLS, {
        entries = {
            {
                id = skills.SK_INVOCATIONS,
                level = 0,
                points = halfway,
            },
        },
    })

    local bounds = {}

    function game:random(_, bound)
        bounds[#bounds + 1] = bound

        return 0
    end

    local creature = plants.spawn(game, player,
        monsters.MONS_BRIAR_PATCH, 31, 20, 2)
    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_BRIAR_PATCH)
    local stats = game:get(creature, component.SUMMON_STATS)
    local state = game:get(creature, component.SUMMON)
    local health = game:get(creature, component.HEALTH)

    harness.equal(stats.hd, definition.hd + 1)
    harness.equal(health.max, 11)
    harness.equal(state.expires_aut, 270)
    harness.equal(bounds[1], 256)
    harness.equal(bounds[2], 1280)
end

-- One Overgrow aim converts its wall and a neighboring wall, while a
-- permanent wall and a vault veto remain intact.
local function check_overgrow(game, player)
    local overgrow = registry.get(abilities.FEDHAS_OVERGROW)

    game.cells["25:20"] = terrain.DNGN_ROCK_WALL
    game.cells["25:21"] = terrain.DNGN_STONE_WALL
    game.cells["25:19"] = terrain.DNGN_PERMAROCK_WALL
    game.cells["26:20"] = terrain.DNGN_TREE
    game.blood = { ["25:20"] = true }

    function game:cell_blood(_, x, y)
        return self.blood[x .. ":" .. y] == true
    end

    function game:set_cell_blood(_, x, y, bloody)
        self.blood[x .. ":" .. y] = bloody
    end

    function game:marker_property(_, x, y, name)
        if x == 26 and y == 20 and name == "veto_destroy" then
            return "veto"
        end

        return nil
    end

    harness.truthy(overgrow.prepare(game, player, { dx = 5, dy = -1 }))
    harness.falsy(overgrow.prepare(game, player, { dx = 5, dy = 0 }))
    overgrow.resolve(game, player, { dx = 5, dy = 0 })

    harness.equal(game:cell(1, 25, 20), terrain.DNGN_FLOOR)
    harness.falsy(game:cell_blood(1, 25, 20))
    harness.equal(game:cell(1, 25, 21), terrain.DNGN_FLOOR)
    harness.equal(game:cell(1, 25, 19), terrain.DNGN_PERMAROCK_WALL)
    harness.equal(game:cell(1, 26, 20), terrain.DNGN_TREE)
    harness.truthy(game:actor_at(1, 25, 20))
    harness.truthy(game:actor_at(1, 25, 21))

    -- The real level indexes the player as an actor. An open door under
    -- that player must not be mistaken for a visible monster or crash.
    game:add(player, component.ACTOR, {
        kind_id = "player",
        speed = 10,
    })
    game.cells["20:20"] = terrain.DNGN_OPEN_DOOR
    harness.falsy(overgrow.prepare(game, player, { dx = 0, dy = 0 }))
    overgrow.resolve(game, player, { dx = 0, dy = 0 })
    harness.equal(game:cell(1, 20, 20), terrain.DNGN_FLOOR)
end

-- This single slice test holds the four registry contracts together.
function test.run(ctx)
    local game, player = worshipper(ctx)

    check_ranks(game, player)
    check_summons(game, player)
    check_overgrow(game, player)
    check_fractional_skill(ctx)
    check_passage(ctx)
end

return test
