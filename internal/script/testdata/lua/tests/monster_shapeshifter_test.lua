local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local shapeshifter = require("policy.monsters.shapeshifter")
local factory = require("policy.population.factory")
local effects = require("policy.combat.monster_target_brands.chaos_effects")
local effect_ids = require("constants.chaos_effects")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local shape_draw = require("tests.monster_shapeshifter_fixture")

local test = {}

-- A distant but legal form becomes available only after source-like failed
-- random picks widen the power band. The pool comes from production code.
local function relaxed_random_form(ctx)
    local target = fixture.actor(ctx, monsters.MONS_SHAPESHIFTER,
        60, 60, 20)
    local game = fixture.context(ctx, target)
    local source = catalog.get("monsters", monsters.MONS_SHAPESHIFTER)
    local pool = polymorph.shifter_pool(game, {
        level_id = 1,
        x = 60,
        y = 60,
    })
    local rat_index

    for index, definition in ipairs(pool) do
        if definition.id == monsters.MONS_RAT then
            rat_index = index - 1
            break
        end
    end

    harness.truthy(rat_index, "land form pool includes the rat species")

    local attempts = 0

    game.random = function(_, _, bound)
        if bound == #pool then
            return rat_index
        end

        if bound == 200 then
            attempts = attempts + 1
        end

        return 0
    end

    harness.truthy(polymorph.random_shifter(game, target, source),
        "power relaxation eventually admits a distant natural form")
    harness.equal(ctx:get(target, component.ACTOR).kind_id,
        monsters.MONS_RAT, "uniform source draw selects the rat")
    harness.truthy(attempts >= 5,
        "failed picks widen the power band before rat is accepted")
end

-- A generated shifter must leave its base profile immediately. This uses
-- actual catalog records and component schemas, not a copied form table.
local function natural_spawn(ctx, kind_id)
    local monster = fixture.actor(ctx, kind_id, 30, 30, 20)
    local game = fixture.context(ctx, monster)

    game.random = shape_draw.stable_draw(game, kind_id, 30, 30)

    shapeshifter.attach(game, monster, kind_id)

    local shape = ctx:get(monster, component.MONSTER_SHAPESHIFTER)
    local form = ctx:get(monster, component.MONSTER_POLYMORPH)
    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    harness.truthy(shape, "a natural shifter has durable identity")
    harness.equal(shape.original_kind_id, kind_id,
        "the source species remains known after its first change")
    harness.truthy(form, "the body transition records source lineage")
    harness.equal(form.original_kind_id, kind_id,
        "save lineage identifies the source shapeshifter")
    harness.truthy(actor.kind_id ~= kind_id,
        "placement changes the base profile immediately")
    harness.truthy(definition.status == "defined",
        "the new form comes from a playable catalog definition")

    return game, monster, actor.kind_id
end

-- Ordinary and glowing monsters use the same persistent owner, with their
-- variant retained even after both bodies have changed shape.
function test.run(ctx)
    relaxed_random_form(ctx)

    local ordinary, ordinary_actor = natural_spawn(ctx,
        monsters.MONS_SHAPESHIFTER)
    local glowing, glowing_actor = natural_spawn(ctx,
        monsters.MONS_GLOWING_SHAPESHIFTER)

    harness.truthy(shapeshifter.active(ordinary, ordinary_actor),
        "ordinary shifter remains active under its borrowed body")
    harness.truthy(shapeshifter.active(glowing, glowing_actor),
        "glowing shifter remains active under its borrowed body")

    -- The glowing variant rolls one chance in four. A missed chance must
    -- leave its current body alone even when the catalog offers new forms.
    local glowing_before = ctx:get(glowing_actor, component.ACTOR).kind_id

    glowing.random = function(_, _, bound)
        if bound == 4 then
            return 1
        end

        return 0
    end

    harness.falsy(shapeshifter.tick(glowing, glowing_actor),
        "glowing shifter keeps its form on a missed chance")
    harness.equal(ctx:get(glowing_actor, component.ACTOR).kind_id,
        glowing_before, "a missed glowing chance leaves the body intact")

    -- RANDOM_MONSTER checks the destination cell, not whether the new body
    -- shares the old body's flight. A flying bat can become a land rat here.
    local bat = catalog.get("monsters", monsters.MONS_BAT)
    local rat_form = catalog.get("monsters", monsters.MONS_RAT)

    harness.truthy(polymorph.shifter_eligible(ordinary, bat, rat_form, {
        level_id = 1,
        x = 30,
        y = 30,
    }), "a flying shifter may become a ground monster on dry floor")

    -- Generation and authored placement both use this factory. A natural
    -- monster must start in another form before the first decision tick.
    local generated = fixture.observed_context(ctx)

    generated.random = shape_draw.stable_draw(generated,
        monsters.MONS_SHAPESHIFTER, 40, 40)

    local spawned = factory.spawn(generated,
        monsters.MONS_SHAPESHIFTER, 1, 40, 40)

    harness.truthy(shapeshifter.active(generated, spawned),
        "population attaches the persistent shape owner")
    harness.truthy(ctx:get(spawned, component.ACTOR).kind_id ~=
        monsters.MONS_SHAPESHIFTER,
        "population changes the base body before AI acts")

    -- Incapacitation pauses shape changes but leaves identity attached.
    local before = ctx:get(ordinary_actor, component.ACTOR).kind_id

    ctx:add(ordinary_actor, component.PARALYSIS, {
        remaining_aut = 10,
    })
    harness.falsy(shapeshifter.tick(ordinary, ordinary_actor),
        "paralysis suppresses a form-change attempt")
    harness.equal(ctx:get(ordinary_actor, component.ACTOR).kind_id,
        before, "paralysis preserves the borrowed body")
    ctx:remove(ordinary_actor, component.PARALYSIS)

    ctx:add(ordinary_actor, component.MONSTER_STASIS, {
        hibernating = true,
    })
    harness.falsy(shapeshifter.tick(ordinary, ordinary_actor),
        "hibernation suppresses a form-change attempt")
    ctx:remove(ordinary_actor, component.MONSTER_STASIS)

    ordinary.random = shape_draw.stable_draw(ordinary, before,
        30, 30, before)

    harness.truthy(shapeshifter.tick(ordinary, ordinary_actor),
        "an eligible action can choose a later form")
    harness.truthy(ctx:get(ordinary_actor, component.ACTOR).kind_id ~= before,
        "later form selection changes the body")

    -- Chaos creates the same permanent owner on an ordinary natural actor.
    local rat = fixture.actor(ctx, monsters.MONS_RAT, 50, 50, 10)
    local chaos = fixture.context(ctx, rat)

    chaos.random = shape_draw.stable_draw(chaos,
        monsters.MONS_RAT, 50, 50)

    effects.apply_named(chaos, effect_ids.SHIFTER, {
        attacker = ordinary_actor,
        defender = rat,
        definition = catalog.get("monsters", monsters.MONS_RAT),
        damage_done = 10,
        health = ctx:get(rat, component.HEALTH),
    })

    harness.truthy(shapeshifter.active(chaos, rat),
        "Chaos conversion creates permanent shape identity")
    harness.equal(ctx:get(rat, component.MONSTER_SHAPESHIFTER)
        .original_kind_id, monsters.MONS_RAT,
        "Chaos conversion preserves its original species")
end

return test
