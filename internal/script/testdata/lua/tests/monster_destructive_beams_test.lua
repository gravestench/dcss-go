-- Missing book spells share the normal beam owner, while destruction
-- selects a source projectile at each cast. These tests use live ECS actors.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local destruction = require(
    "policy.combat.monster_spells.destruction")
local barbs_policy = require("policy.combat.barbs")

local test = {}

-- A friendly caster can fire through open floor at an enemy actor without
-- constructing a second copy of the production beam or spell schemas.
local function actors(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_WIZARD,
        20, 20, 500)
    local target = fixture.actor(ctx, monsters.MONS_RAT,
        23, 20, 500)

    ctx:add(caster, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    function game:random()
        return 0
    end

    return game, caster, target
end

-- Every source book ID must plan and resolve through the same registered
-- intent family; the damage assertion catches a profile with no effect.
local function casts(ctx, game, caster, target, spell_id)
    local effect = effects.effect(spell_id)
    local plan = effect.plan(game, caster, target)
    local before = ctx:get(target, component.HEALTH).current

    harness.truthy(plan, spell_id .. " plans a reachable target")
    effect.resolve(game, caster, target, nil, plan)
    harness.truthy(ctx:get(target, component.HEALTH).current < before,
        spell_id .. " damages the target")
end

-- The two source selectors use fixed draw bands. Assert their boundaries
-- without copying a production catalog or redefining spell schemas.
local function source_choices()
    local major = {
        spells.SPELL_BOLT_OF_FIRE,
        spells.SPELL_FIREBALL,
        spells.SPELL_LIGHTNING_BOLT,
        spells.SPELL_STICKY_FLAME,
        spells.SPELL_IRON_SHOT,
        spells.SPELL_BOLT_OF_DRAINING,
        spells.SPELL_ORB_OF_ELECTRICITY,
    }
    local draw_context = {}

    function draw_context:random(_, bound)
        harness.truthy(self.draw < bound,
            "source selection draw stays inside its pool")

        return self.draw
    end

    for draw, expected in ipairs(major) do
        draw_context.draw = draw - 1
        harness.equal(destruction.major_choice(draw_context),
            expected, "Major Destruction source choice " .. draw)
    end

    for _, boundary in ipairs({
        {
            draw = 0,
            spell = spells.SPELL_FIREBALL,
        },

        {
            draw = 24,
            spell = spells.SPELL_FIREBALL,
        },

        {
            draw = 25,
            spell = spells.SPELL_ICEBLAST,
        },

        {
            draw = 44,
            spell = spells.SPELL_ICEBLAST,
        },

        {
            draw = 45,
            spell = spells.SPELL_GHOSTLY_FIREBALL,
        },

        {
            draw = 59,
            spell = spells.SPELL_GHOSTLY_FIREBALL,
        },
    }) do
        draw_context.draw = boundary.draw
        harness.equal(destruction.legendary_choice(draw_context),
            boundary.spell,
            "Legendary Destruction source band " .. boundary.draw)
    end
end

-- Throw Barbs declines melee-distance foes. The two destruction wrappers
-- select their own projectiles and Legendary fires twice in one action.
function test.run(ctx)
    local game, caster, target = actors(ctx)

    source_choices()
    casts(ctx, game, caster, target, spells.SPELL_THROW_BARBS)
    local lodged = ctx:get(target, component.BARBS)

    harness.truthy(lodged and lodged.remaining_aut > 0,
        "Throw Barbs lodges saved spikes after a damaging hit")

    local before_move = ctx:get(target, component.HEALTH).current

    barbs_policy.moved(game, target, 10)
    harness.truthy(ctx:get(target, component.HEALTH).current < before_move,
        "lodged spikes damage the moving monster")

    barbs_policy.tick(game, target, 10)

    local aged = ctx:get(target, component.BARBS)

    casts(ctx, game, caster, target, spells.SPELL_THROW_BARBS)

    local stacked = ctx:get(target, component.BARBS)

    harness.equal(stacked.power, 2,
        "a second hit stacks monster barbs degree")
    harness.equal(stacked.remaining_aut, aged.remaining_aut + 50,
        "a second hit adds its full source enchantment duration")
    casts(ctx, game, caster, target,
        spells.SPELL_MAJOR_DESTRUCTION)
    casts(ctx, game, caster, target,
        spells.SPELL_LEGENDARY_DESTRUCTION)

    -- Select each newly imported child in the live beam resolver. A
    -- separate choice draw during planning is preserved for Major.
    for _, draw in ipairs({ 3, 6 }) do
        local selections = 0

        function game:random(_, bound)
            if bound == 7 and selections < 2 then
                selections = selections + 1

                return draw
            end

            return 0
        end

        casts(ctx, game, caster, target,
            spells.SPELL_MAJOR_DESTRUCTION)
    end

    local adjacent = fixture.actor(ctx, monsters.MONS_RAT,
        21, 20, 500)
    local barbs = effects.effect(spells.SPELL_THROW_BARBS)

    harness.falsy(barbs.plan(game, caster, adjacent),
        "Throw Barbs refuses melee-range targets")
end

return test
