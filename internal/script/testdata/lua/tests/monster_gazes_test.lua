-- The actual gaze modules share a direct-sight plan. These fixtures use
-- production spell IDs and effects, never a copied spell registry.
local component = require("constants.component")
local harness = require("tests.harness")
local melee = require("policy.combat.melee")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local revival_statuses = require("constants.revival_statuses")
local effects = require("policy.combat.monster_spells")
local weakness = require("policy.combat.player_weakness")
local spells = require("ids.spells")
local species = require("ids.species")

local test = {}
local caster = 101
local foe = 202

-- A nearby target can be seen even if an unrelated actor stands between
-- it and the caster. Gaze planning must not ask for projectile clearance.
local function context()
    local values = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_GOLDEN_EYE,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 1,
                y = 1,
            },
        },
        [foe] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_ADDER,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 3,
                y = 1,
            },
            [component.HEALTH] = {
                current = 30,
                max = 30,
            },
        },
    }
    local ctx = {
        values = values,
        sight = true,
        projectile_calls = 0,
        messages = {},
    }

    -- The selected foe is another actor; a player is unnecessary for
    -- the direct-sight contract in this first test.
    function ctx:player()
        return 999
    end

    -- Planning reads only current ECS components.
    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    -- All status owners write through the same live ECS view.
    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    -- Match only entities with every requested component, as the real ECS
    -- does when resistance scans mutations or equipment.
    function ctx:query(ids)
        local found = {}

        for entity, entries in pairs(self.values) do
            local matches = true

            for _, id in ipairs(ids) do
                matches = matches and entries[id] ~= nil
            end

            if matches then
                found[#found + 1] = entity
            end
        end

        table.sort(found)

        return found
    end

    -- Replacing a detached component keeps the updated timer observable.
    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    -- A first enchantment creates a component on its affected actor.
    function ctx:add(entity, id, value)
        self.values[entity][id] = value
    end

    -- Expired status cannot affect a later melee action.
    function ctx:remove(entity, id)
        self.values[entity][id] = nil
    end

    -- The high will roll fails a save; other draws use their minimum.
    function ctx:random(_, bound)
        harness.truthy(bound > 0, "gaze draw bound is positive")

        if bound == 100 or bound == 101 then
            return bound - 1
        end

        return 0
    end

    -- The production status owners report their visible effect to a client.
    function ctx:emit(kind, message)
        self.messages[#self.messages + 1] = {
            kind = kind,
            message = message,
        }
    end

    -- Geometric sight is independent of any occupant on the ray.
    function ctx:visible()
        return self.sight
    end

    -- Make a mistakenly reused bolt path observable in the test.
    function ctx:projectile_clear()
        self.projectile_calls = self.projectile_calls + 1
        return false
    end

    return ctx
end

-- All four source gazes use one entity-plan contract. Visibility tests
-- distinguish walls, blindness, invisibility, and see-invisible.
local function check_plan_visibility()
    local ids = {
        spells.SPELL_CONFUSION_GAZE,
        spells.SPELL_PARALYSIS_GAZE,
        spells.SPELL_DRAINING_GAZE,
        spells.SPELL_WEAKENING_GAZE,
    }

    for _, id in ipairs(ids) do
        local ctx = context()
        local effect = effects.effect(id)
        local plan = effect.plan(ctx, caster, foe)

        harness.truthy(plan and plan.entity == foe,
            id .. " sees the selected foe through an actor")
        harness.equal(ctx.projectile_calls, 0,
            id .. " does not trace a projectile")

        ctx.sight = false
        harness.falsy(effect.plan(ctx, caster, foe),
            id .. " cannot target a hidden foe")
    end

    local unseen = context()
    local gaze = effects.effect(spells.SPELL_CONFUSION_GAZE)

    unseen.values[foe][component.ACTOR].kind_id =
        monsters.MONS_UNSEEN_HORROR
    unseen.values[caster][component.ACTOR].kind_id = monsters.MONS_ADDER
    harness.falsy(gaze.plan(unseen, caster, foe),
        "a gaze cannot target an intrinsically invisible foe")
    unseen.values[caster][component.ACTOR].kind_id = monsters.MONS_BORIS
    harness.truthy(gaze.plan(unseen, caster, foe),
        "see invisible permits a gaze at an unseen foe")

    local hidden = context()

    hidden.values[caster][component.ACTOR].kind_id = monsters.MONS_ADDER
    hidden.values[foe][component.MONSTER_ENCHANT] = {
        invisible_aut = 20,
        blind_aut = 0,
    }
    harness.falsy(gaze.plan(hidden, caster, foe),
        "a saved invisibility status hides the foe from gazes")
    hidden.values[foe][component.HEX_STATUS] = {
        corona_aut = 10,
    }
    harness.truthy(gaze.plan(hidden, caster, foe),
        "Corona reveals an otherwise invisible gaze target")

    local blinded = context()

    blinded.values[caster][component.MONSTER_ENCHANT] = {
        blind_aut = 20,
        invisible_aut = 0,
    }
    harness.falsy(gaze.plan(blinded, caster, foe),
        "a blind caster cannot establish a gaze")
end

-- Confusion tests the normal monster result and the player's clarity gate
-- after a failed will contest, using production mutation registration.
local function check_confusion()
    local confused = context()
    local confusion = effects.effect(spells.SPELL_CONFUSION_GAZE)

    confusion.resolve(confused, caster, foe, nil,
        confusion.plan(confused, caster, foe))
    harness.truthy(confused:get(foe,
        component.MONSTER_CONFUSION).remaining_aut > 0,
        "Confusion Gaze stores monster confusion after failed will")

    local clear_mind = context()

    clear_mind.values[foe][component.PLAYER] = {
        species_id = species.SP_HUMAN,
    }
    clear_mind.values[foe][component.PROGRESSION] = {
        level = 1,
    }
    clear_mind.values[303] = {
        [component.MUTATION] = {
            owner = foe,
            mutation_id = mutations.MUT_CLARITY,
            innate = 0,
            acquired = 1,
            temporary = 0,
        },
    }
    confusion.resolve(clear_mind, caster, foe, nil,
        confusion.plan(clear_mind, caster, foe))
    harness.falsy(clear_mind:get(foe,
        "zap.player_confusion"),
        "Clarity prevents player confusion after a failed will contest")
end

-- A gaze cannot refresh current paralysis or bypass innate player stasis.
local function check_paralysis()
    local paralyzed = context()
    paralyzed.values[foe][component.PLAYER] = {
        species_id = species.SP_HUMAN,
    }
    local paralysis = effects.effect(spells.SPELL_PARALYSIS_GAZE)
    local paralysis_plan = paralysis.plan(paralyzed, caster, foe)

    paralysis.resolve(paralyzed, caster, foe, nil, paralysis_plan)
    harness.equal(paralyzed:get(foe,
        component.PLAYER_PARALYSIS).remaining_aut, 20,
        "Paralysis Gaze starts at source's two-turn minimum")
    paralysis.resolve(paralyzed, caster, foe, nil, paralysis_plan)
    harness.equal(paralyzed:get(foe,
        component.PLAYER_PARALYSIS).remaining_aut, 20,
        "a repeated gaze does not extend current paralysis")

    local monster_paralyzed = context()

    monster_paralyzed.values[foe][component.PARALYSIS] = {
        remaining_aut = 10,
    }
    paralysis.resolve(monster_paralyzed, caster, foe, nil,
        paralysis.plan(monster_paralyzed, caster, foe))
    harness.equal(monster_paralyzed:get(foe,
        component.PARALYSIS).remaining_aut, 10,
        "a repeated gaze leaves a monster's paralysis unchanged")

    local stasis = context()

    stasis.values[foe][component.PLAYER] = {
        species_id = species.SP_FORMICID,
    }
    paralysis.resolve(stasis, caster, foe, nil,
        paralysis.plan(stasis, caster, foe))
    harness.falsy(stasis:get(foe, component.PLAYER_PARALYSIS),
        "innate stasis blocks Paralysis Gaze before its duration roll")
end

-- MP drain heals a Ghost Moth only by the amount actually removed, and HP
-- remains capped by the caster's live maximum.
local function check_draining()
    local drained = context()
    drained.values[foe][component.PLAYER] = {}
    drained.values[foe][component.MAGIC] = {
        current = 10,
        max = 10,
    }
    drained.values[caster][component.ACTOR].kind_id =
        monsters.MONS_GHOST_MOTH
    drained.values[caster][component.HEALTH] = {
        current = 10,
        max = 11,
    }

    -- A nonzero source draw proves MP loss instead of only exercising a
    -- legitimate zero-drain cast.
    function drained:random(_, bound)
        return bound - 1
    end

    local draining = effects.effect(spells.SPELL_DRAINING_GAZE)

    draining.resolve(drained, caster, foe, nil,
        draining.plan(drained, caster, foe))
    harness.truthy(drained:get(foe, component.MAGIC).current < 10,
        "Draining Gaze removes player MP without beam contact")
    harness.equal(drained:get(caster, component.HEALTH).current, 11,
        "Ghost Moth heals from MP actually drained, capped by max HP")

    local empty = context()

    empty.values[foe][component.PLAYER] = {}
    empty.values[foe][component.MAGIC] = {
        current = 0,
        max = 10,
    }
    empty.values[caster][component.ACTOR].kind_id =
        monsters.MONS_GHOST_MOTH
    empty.values[caster][component.HEALTH] = {
        current = 10,
        max = 30,
    }
    draining.resolve(empty, caster, foe, nil,
        draining.plan(empty, caster, foe))
    harness.equal(empty:get(caster, component.HEALTH).current, 10,
        "an empty MP pool gives a Ghost Moth no healing")
end

-- Weak lasts in a saved component, scales raw player melee, and expires
-- by elapsed aut rather than assuming each action costs ten.
local function check_player_weakness()
    local weakened = context()
    weakened.values[foe][component.PLAYER] = {}
    local weakening = effects.effect(spells.SPELL_WEAKENING_GAZE)

    weakening.resolve(weakened, caster, foe, nil,
        weakening.plan(weakened, caster, foe))
    harness.truthy(weakened:get(foe,
        component.PLAYER_WEAKNESS).remaining_aut > 0,
        "Weakening Gaze saves a player-owned duration")
    harness.equal(weakness.melee_damage(weakened, foe, 8), 6,
        "Weak reduces raw melee damage to three quarters")
    weakness.tick(weakened, foe, 1000)
    harness.falsy(weakened:get(foe, component.PLAYER_WEAKNESS),
        "Weak expires by actual elapsed aut")
end

-- Monster Weak must scale raw attack damage before defender armour; the
-- maximal deterministic draws make the ordering observable.
local function check_monster_weakness()
    local striker = context()

    -- Maximum draws expose whether Weak runs before or after four AC.
    function striker:random(_, bound)
        return bound - 1
    end

    local attack = {
        attacker = caster,
        damage = 12,
        type_id = "AT_HIT",
    }
    local defense = {
        ac = 4,
        gdr = 0,
    }
    local ordinary_damage = melee.monster_damage(striker, attack, defense)

    striker.values[caster][component.MONSTER_ENFEEBLE] = {
        weak_aut = 50,
    }

    local weak_damage = melee.monster_damage(striker, attack, defense)

    harness.equal(ordinary_damage, 8,
        "ordinary monster hit rolls damage then player armour")
    harness.equal(weak_damage, 4,
        "monster Weak scales raw melee before player armour")
end

-- Revival's clearing list is the production owner for temporary status
-- cleanup, so Weak belongs there instead of surviving another life.
local function check_revival()
    local cleared_on_revival = false

    for _, id in ipairs(revival_statuses) do
        cleared_on_revival = cleared_on_revival or
            id == component.PLAYER_WEAKNESS
    end

    harness.truthy(cleared_on_revival,
        "revival clears player Weak with other temporary statuses")
end

-- Run each source behavior as a named, independent fixture scenario.
function test.run()
    check_plan_visibility()
    check_confusion()
    check_paralysis()
    check_draining()
    check_player_weakness()
    check_monster_weakness()
    check_revival()
end

return test
