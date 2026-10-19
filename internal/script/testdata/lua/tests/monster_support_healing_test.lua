local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local terrain = require("constants.terrain")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- An HD-nine caster exercises Minor Healing's nonempty two-die range.
local function caster(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.ACTOR, {
        kind_id = monsters.MONS_ORC_SORCERER,
        speed = 10,
    })

    ctx:add(entity, component.HEALTH, {
        current = 20,
        max = 100,
    })

    ctx:add(entity, component.POSITION, {
        level_id = 1,
        x = 5,
        y = 5,
    })

    return entity
end

-- The Lua rule harness has no grid service; this sparse grid stands for
-- one adjacent tree while component reads still use the real ECS context.
local function wooded_context(ctx, has_tree)
    local game = setmetatable({}, { __index = ctx })

    function game.cell(_, _, x, y)
        if has_tree and x == 6 and y == 5 then
            return terrain.DNGN_TREE
        end

        return terrain.DNGN_FLOOR
    end

    function game.actor_at()
        return nil
    end

    return game
end

-- Each heal uses source eligibility and clamps HP through the owned health
-- component. A cast at too much HP must never be planned.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local minor_caster = caster(ctx)
    local minor = effects.effect(spells.SPELL_MINOR_HEALING)
    local minor_plan = minor.plan(game, minor_caster)

    minor.resolve(game, minor_caster, nil, nil, minor_plan)

    harness.equal(ctx:get(minor_caster, component.HEALTH).current, 25,
        "Minor Healing adds three plus its two minimum dice")

    local major_caster = caster(ctx)
    local major = effects.effect(spells.SPELL_MAJOR_HEALING)
    local major_plan = major.plan(game, major_caster)

    major.resolve(game, major_caster, nil, nil, major_plan)

    harness.equal(ctx:get(major_caster, component.HEALTH).current, 70,
        "Major Healing adds fifty plus the source average roll")
    harness.falsy(major.plan(game, major_caster),
        "a monster over half HP does not choose Major Healing")

    local wood_caster = caster(ctx)
    local no_tree = wooded_context(game, false)
    local with_tree = wooded_context(game, true)
    local woodweal = effects.effect(spells.SPELL_WOODWEAL)

    harness.falsy(woodweal.plan(no_tree, wood_caster),
        "Woodweal needs adjacent living or petrified wood")

    local wood_plan = woodweal.plan(with_tree, wood_caster)

    woodweal.resolve(with_tree, wood_caster, nil, nil, wood_plan)

    harness.equal(ctx:get(wood_caster, component.HEALTH).current, 55,
        "Woodweal heals without consuming the tree")
    harness.equal(with_tree:cell(1, 6, 5), terrain.DNGN_TREE,
        "Woodweal preserves adjacent terrain")
end

return test
