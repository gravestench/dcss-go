-- Direct strikes share a target contract but retain four separate source
-- damage rules. This fixture uses production definitions and effects.
local catalog = require("policy.catalog")
local component = require("constants.component")
local attitudes = require("constants.attitude")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local effects = require("policy.combat.monster_spells")
local spells = require("ids.spells")

local test = {}
local caster = 101
local foe = 202
local construct = 303

-- Keep the ray clear while controlling visibility, adjacent air, and one
-- allied nonliving actor. A zero RNG draw exposes each formula's minimum.
local function context()
    local values = {
        [999] = {
            [component.POSITION] = {
                level_id = 1,
                x = 6,
                y = 6,
            },
        },
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_ORC_WIZARD,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 1,
                y = 1,
            },
            [component.HEALTH] = {
                current = 50,
                max = 50,
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
                current = 100,
                max = 100,
            },
            [component.SUMMON] = {
                attitude = attitudes.FRIENDLY,
            },
        },
        [construct] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_GUARDIAN_GOLEM,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 3,
                y = 0,
            },
            [component.HEALTH] = {
                current = 50,
                max = 50,
            },
        },
    }
    local ctx = {
        values = values,
        messages = {},
        sight = true,
    }

    -- The observer sees this encounter and receives its visible messages.
    function ctx:player()
        return 999
    end

    -- ECS reads expose the same live fields that production policies use.
    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    -- Presence checks distinguish actors from players and optional statuses.
    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    -- Health effects write through the ECS context rather than a test copy.
    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    -- Optional equipment queries see an empty floor inventory.
    function ctx:query()
        return {}
    end

    -- Every in-bounds square is floor; an actor can stand between the two.
    function ctx:walkable()
        return true
    end

    -- Geometry decides visibility, independently of projectile occupancy.
    function ctx:visible()
        return self.sight
    end

    -- Airstrike and resonance inspect the actors adjacent to their foe.
    function ctx:actor_at(_, x, y)
        for entity, fields in pairs(self.values) do
            local position = fields[component.POSITION]

            if position and position.x == x and position.y == y then
                return entity
            end
        end
    end

    -- Fixed draws make source lower bounds exact and reproducible.
    function ctx:random(_, bound)
        harness.truthy(bound > 0, "random bound is positive")
        return 0
    end

    -- Messages remain observable without a terminal client.
    function ctx:emit(kind, message)
        self.messages[#self.messages + 1] = {
            kind,
            message,
        }
    end

    return ctx
end

-- The full policy path must plan, validate, and change saved health for
-- every direct strike, while rejecting a stale or invisible target.
function test.run()
    local ids = {
        spells.SPELL_SMITING,
        spells.SPELL_AIRSTRIKE,
        spells.SPELL_WATERSTRIKE,
        spells.SPELL_RESONANCE_STRIKE,
    }

    for _, id in ipairs(ids) do
        local ctx = context()
        local effect = effects.effect(id)
        local plan = effect.plan(ctx, caster, foe)
        local before = ctx:get(foe, component.HEALTH).current

        harness.truthy(plan, id .. " plans a visible target")
        effect.resolve(ctx, caster, foe, nil, plan)
        harness.truthy(ctx:get(foe, component.HEALTH).current < before,
            id .. " damages the selected actor")
        harness.truthy(#ctx.messages > 0, id .. " announces the strike")

        ctx.sight = false
        harness.falsy(effect.plan(ctx, caster, foe),
            id .. " rejects an invisible target")
    end

    local smite = effects.effect(spells.SPELL_SMITING)
    local ctx = context()
    local plan = smite.plan(ctx, caster, foe)

    smite.resolve(ctx, caster, foe, nil, plan)
    harness.equal(ctx:get(foe, component.HEALTH).current, 93,
        "Smiting bypasses armour and deals source minimum seven")

    local alternate = context()
    local wrong_plan = {
        kind = plan.kind,
        entity = construct,
    }
    local valid = pcall(smite.resolve, alternate, caster, foe,
        nil, wrong_plan)

    harness.falsy(valid, "a stale entity plan cannot retarget Smiting")

    alternate.values[foe][component.POSITION].x = 12
    harness.falsy(smite.plan(alternate, caster, foe),
        "a direct strike cannot exceed catalogued LOS range")

    local air = context()
    air.values[construct][component.POSITION].x = 2
    air.values[construct][component.POSITION].y = 1
    local airstrike = effects.effect(spells.SPELL_AIRSTRIKE)

    harness.truthy(airstrike.plan(air, caster, foe),
        "an intervening actor cannot intercept Airstrike")
    air.values[construct][component.POSITION].x = 3
    air.values[construct][component.POSITION].y = 0
    airstrike.resolve(air, caster, foe, nil,
        airstrike.plan(air, caster, foe))
    harness.equal(air:get(foe, component.HEALTH).current, 86,
        "seven empty neighbours contribute fourteen Airstrike damage")

    local player_nearby = context()
    player_nearby.values[999] = {
        [component.PLAYER] = {},
        [component.POSITION] = {
            level_id = 1,
            x = 3,
            y = 2,
        },
    }

    airstrike.resolve(player_nearby, caster, foe, nil,
        airstrike.plan(player_nearby, caster, foe))
    harness.equal(player_nearby:get(foe, component.HEALTH).current, 86,
        "a player beside the foe does not remove source empty air")

    local water = context()
    local waterstrike = effects.effect(spells.SPELL_WATERSTRIKE)
    water.values[foe][component.ACTOR].kind_id = monsters.MONS_GOBLIN

    waterstrike.resolve(water, caster, foe, nil,
        waterstrike.plan(water, caster, foe))
    harness.equal(water:get(foe, component.HEALTH).current, 97,
        "three minimum Waterstrike dice each contribute one")

    local immune = context()
    immune.values[foe][component.ACTOR].kind_id =
        monsters.MONS_GUARDIAN_GOLEM
    waterstrike.resolve(immune, caster, foe, nil,
        waterstrike.plan(immune, caster, foe))
    harness.equal(immune:get(foe, component.HEALTH).current, 98,
        "nonliving targets keep only the impact share of water damage")

    local flying = context()
    flying.values[foe][component.ZAP_FLIGHT] = {
        remaining_aut = 20,
    }

    waterstrike.resolve(flying, caster, foe, nil,
        waterstrike.plan(flying, caster, foe))
    harness.truthy(flying.messages[#flying.messages][2]:find(
        "rises up", 1, true),
        "water rises up to strike an airborne actor")

    local resonance = effects.effect(spells.SPELL_RESONANCE_STRIKE)
    local aligned = context()

    resonance.resolve(aligned, caster, foe, nil,
        resonance.plan(aligned, caster, foe))
    harness.equal(aligned:get(foe, component.HEALTH).current, 96,
        "one allied construct stochastically grants a fourth die")

    local enemy_construct = context()
    enemy_construct.values[construct][component.SUMMON] = {
        attitude = attitudes.FRIENDLY,
    }
    resonance.resolve(enemy_construct, caster, foe, nil,
        resonance.plan(enemy_construct, caster, foe))
    harness.equal(enemy_construct:get(foe, component.HEALTH).current, 97,
        "a construct on the target's side adds no resonance die")

    local near_caster = context()
    near_caster.values[caster][component.ACTOR].kind_id =
        monsters.MONS_GUARDIAN_GOLEM
    near_caster.values[caster][component.POSITION].x = 2
    near_caster.values[caster][component.SUMMON] = {
        attitude = attitudes.FRIENDLY,
    }
    near_caster.values[foe][component.SUMMON].attitude =
        attitudes.HOSTILE
    near_caster.values[construct][component.SUMMON] = {
        attitude = attitudes.GOOD_NEUTRAL,
    }

    -- A high remainder draw denies an odd construct count its extra die,
    -- distinguishing the correct two-construct count from one.
    function near_caster:random(_, bound)
        return bound - 1
    end

    resonance.resolve(near_caster, caster, foe, nil,
        resonance.plan(near_caster, caster, foe))

    local caster_hd = catalog.get("monsters",
        monsters.MONS_GUARDIAN_GOLEM).hd
    local expected = 100 - (4 * caster_hd - 1)

    harness.equal(near_caster:get(foe, component.HEALTH).current,
        expected,
        "adjacent nonliving caster and good-neutral ally both add power")
end

return test
