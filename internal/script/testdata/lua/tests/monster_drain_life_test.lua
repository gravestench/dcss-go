-- Drain Life should select a self-centered cast only when an unaligned
-- susceptible body is nearby, and should never drain the caster's side.
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local effect = require("policy.combat.monster_spells.drain_life")
local harness = require("tests.harness")
local life = require("policy.combat.life_transfer")
local monster_stats = require("policy.combat.monster_stats")
local monsters = require("ids.monsters")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local test = {}
local caster = 101
local ally = 102
local foe = 201
local second_foe = 202
local distant = 203

-- Supply only the ECS, geometry, and RNG calls the public effect needs.
local function context()
    local state = {
        draws = 0,
        healed = 0,
        hurt = {},
    }
    local positions = {
        [caster] = { level_id = 1, x = 1, y = 1 },
        [ally] = { level_id = 1, x = 2, y = 1 },
        [foe] = { level_id = 1, x = 2, y = 2 },
        [second_foe] = { level_id = 1, x = 3, y = 3 },
        [distant] = { level_id = 1, x = 10, y = 10 },
    }
    local ctx = {}

    -- Query order includes allies and the caster to expose accidental
    -- self-damage rather than hiding it in the fixture.
    function ctx:query()
        return { caster, ally, foe, second_foe, distant }
    end

    -- Source HD and every candidate's current health are live state.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.HEALTH then
            return { current = 20, max = 30 }
        end

        if id == component.ACTOR then
            return { kind_id = monsters.MONS_RAT }
        end
    end

    -- Clear-wall LOS includes the two nearby foes in this fixture.
    function ctx:visible_no_trans()
        return true
    end

    -- One source die is drawn for each actual target, after eligibility.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.MONSTER_SPELL,
            "Drain Life uses the monster spell stream")
        harness.truthy(bound > 0, "damage die has sides")
        state.draws = state.draws + 1

        return 0
    end

    return ctx, state
end

-- Replace neighboring calculations, keeping target iteration and the
-- source spell's HP-transfer formula under test.
local function install_stubs(state)
    local original = {
        aligned = targets.aligned,
        susceptible = life.susceptible,
        resistance = life.resistance,
        hurt = life.hurt,
        heal = life.heal,
        armour = direct.armour,
        hd = monster_stats.spell_hit_dice,
        sees = senses.player_sees_actor,
        sees_cell = senses.player_sees_cell,
    }

    targets.aligned = function(_, _, candidate)
        return candidate == caster or candidate == ally
    end

    life.susceptible = function()
        return true
    end

    life.resistance = function()
        return 0
    end

    direct.armour = function(_, _, raw)
        return raw
    end

    life.hurt = function(_, _, victim, raw)
        harness.equal(raw, 1, "minimum source die reaches each foe")
        state.hurt[#state.hurt + 1] = victim

        return 2
    end

    life.heal = function(_, _, amount)
        state.healed = state.healed + amount

        return amount
    end

    monster_stats.spell_hit_dice = function()
        return 5
    end

    senses.player_sees_actor = function()
        return false
    end

    senses.player_sees_cell = function()
        return false
    end

    return original
end

-- Other Lua tests share cached modules, so restore every stub.
local function restore_stubs(original)
    targets.aligned = original.aligned
    life.susceptible = original.susceptible
    life.resistance = original.resistance
    life.hurt = original.hurt
    life.heal = original.heal
    direct.armour = original.armour
    monster_stats.spell_hit_dice = original.hd
    senses.player_sees_actor = original.sees
    senses.player_sees_cell = original.sees_cell
end

-- The two nearby foes supply actual HP loss; allies and distant creatures
-- consume no dice and contribute no healing.
function test.run()
    local ctx, state = context()
    local original = install_stubs(state)
    local plan = effect.plan(ctx, caster)

    harness.truthy(plan, "an eligible foe permits the cast")
    harness.equal(effect.resolve(ctx, caster, nil, nil, plan), 4,
        "resolver returns total HP taken")
    harness.equal(state.healed, 4,
        "caster heals by the actual total")
    harness.equal(#state.hurt, 2,
        "only two unaligned nearby bodies are hurt")
    harness.equal(state.hurt[1], foe, "first foe is hit")
    harness.equal(state.hurt[2], second_foe, "second foe is hit")
    harness.equal(state.draws, 2,
        "allies and distant bodies consume no damage rolls")

    restore_stubs(original)
end

return test
