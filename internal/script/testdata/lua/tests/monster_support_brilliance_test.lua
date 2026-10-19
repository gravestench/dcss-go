local aura = require("policy.combat.monster_support.brilliance")
local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monster_stats = require("policy.combat.monster_stats")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- The isolated harness supplies the selected player and visibility while
-- keeping actor, book, and status state in the production ECS/catalog.
local function game_context(ctx, player)
    local game = setmetatable({}, { __index = ctx })
    local draws = 0

    function game.player()
        return player
    end

    function game.visible()
        return true
    end

    function game.random(_, stream, bound)
        draws = draws + 1

        return ctx:random(stream, bound)
    end

    function game.draws()
        return draws
    end

    return game
end

-- A Wizard-book monster is an actual spellcaster, unlike a nearby animal.
local function actor(ctx, kind_id, x)
    local entity = ctx:create()

    ctx:add(entity, component.ACTOR, {
        kind_id = kind_id,
        speed = 10,
    })

    ctx:add(entity, component.HEALTH, {
        current = 30,
        max = 30,
    })

    ctx:add(entity, component.POSITION, {
        level_id = 1,
        x = x,
        y = 5,
    })

    return entity
end

-- An eligible ally makes the cast useful and receives +5 spell HD through
-- an independently saved status that can outlast the source aura briefly.
function test.run(ctx)
    local caster = actor(ctx, monsters.MONS_ORC_SORCERER, 5)
    local ally = actor(ctx, monsters.MONS_ORC_SORCERER, 6)
    local animal = actor(ctx, monsters.MONS_RAT, 7)
    local player = actor(ctx, monsters.MONS_RAT, 8)
    local game = game_context(ctx, player)
    local effect = effects.effect(spells.SPELL_AURA_OF_BRILLIANCE)
    local plan = effect.plan(game, caster, player)

    harness.truthy(plan, "nearby Wizard-book ally makes aura useful")

    effect.resolve(game, caster, player, nil, plan)

    harness.truthy(aura.active(game, caster),
        "the source aura is saved on its caster")
    harness.truthy(aura.empowered(game, ally),
        "the eligible allied caster gains saved empowerment")
    harness.falsy(aura.empowered(game, animal),
        "a nearby noncaster is not empowered")

    local definition = catalog.get("monsters", monsters.MONS_ORC_SORCERER)
    local ordinary_hd = monster_stats.hit_dice(game, ally, definition)

    harness.equal(monster_stats.spell_hit_dice(game, ally, definition),
        ordinary_hd + 5, "empowered spells gain five caster HD")
    harness.falsy(effect.plan(game, caster, player),
        "the aura is not recast while active")

    local before = game:get(ally, component.MONSTER_EMPOWERED_SPELLS)
    local draws = game.draws()

    aura.pulse(game, caster)

    local after = game:get(ally, component.MONSTER_EMPOWERED_SPELLS)

    harness.equal(after.remaining_aut, before.remaining_aut,
        "an existing empowerment is not refreshed")
    harness.equal(game.draws(), draws,
        "repeated aura pulses do not draw another duration")

    aura.tick(game, caster, 1000)

    harness.falsy(aura.active(game, caster),
        "the source aura expires on its actor")
    harness.truthy(aura.empowered(game, ally),
        "the ally keeps its separately timed empowerment")

    aura.tick(game, ally, 1000)

    harness.falsy(aura.empowered(game, ally),
        "the ally's empowerment also expires")
end

return test
