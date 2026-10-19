-- Both monster auras use the production spell files and registered ECS IDs.
-- This fixture only supplies the game services needed to place live actors
-- on a small floor and advance one caster action deterministically.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local form_ids = require("constants.form_ids")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local duration = require("policy.combat.monster_support.duration")
local poison_tick = require("systems.magic_monster_toxic_radiance")
local vortex_tick = require("systems.magic_monster_polar_vortex")
local zap_ids = require("policy.magic.effects.zaps.ids")
local terrain = require("constants.terrain")

local test = {}
local caster = 11
local ally = 22
local foe = 33
local player = 44

-- Detached component tables mimic the engine's explicit set/add writes;
-- the catalog and effect modules still come from the production layer.
local function context()
    local values = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_ORC_WIZARD,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 5,
                y = 5,
            },
            [component.HEALTH] = {
                current = 100,
                max = 100,
            },
        },
        [ally] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_GOBLIN,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 5,
                y = 6,
            },
            [component.HEALTH] = {
                current = 100,
                max = 100,
            },
        },
        [foe] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_GOBLIN,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 6,
                y = 5,
            },
            [component.HEALTH] = {
                current = 100,
                max = 100,
            },
            [component.SUMMON] = {
                attitude = attitudes.FRIENDLY,
            },
        },
        [player] = {
            [component.PLAYER] = {},
            [component.PROGRESSION] = { level = 10 },
            [component.POSITION] = {
                level_id = 1,
                x = 25,
                y = 25,
            },
            [component.HEALTH] = {
                current = 100,
                max = 100,
            },
        },
    }
    local ctx = {
        values = values,
        clock = 100,
    }

    -- The player handle is stable even when the player is outside the aura.
    function ctx:player()
        return player
    end

    -- Reads, presence, and writes are the component operations effects use.
    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    function ctx:add(entity, id, value)
        self.values[entity][id] = value
    end

    function ctx:remove(entity, id)
        self.values[entity][id] = nil
    end

    -- Stable query order proves that filtering, not unordered table iteration,
    -- decides who the aura can affect.
    function ctx:query(required)
        local found = {}

        for _, entity in ipairs({ caster, ally, foe, player }) do
            local matches = true

            for _, id in ipairs(required) do
                if not self:has(entity, id) then
                    matches = false
                    break
                end
            end

            if matches then
                found[#found + 1] = entity
            end
        end

        return found
    end

    -- The small fixture has no walls; the distant player remains unseen.
    function ctx:visible_no_trans(_, x, y, radius, to_x, to_y)
        return math.max(math.abs(x - to_x),
            math.abs(y - to_y)) <= radius
    end

    function ctx:visible()
        return false
    end

    function ctx:cell(_, x, y)
        if x >= 0 and x <= 12 and y >= 0 and y <= 12 then
            return terrain.DNGN_FLOOR
        end
    end

    function ctx:walkable(level, x, y)
        return self:cell(level, x, y) ~= nil
    end

    function ctx:actor_at(_, x, y)
        for _, entity in ipairs({ caster, ally, foe, player }) do
            local position = self:get(entity, component.POSITION)

            if position.x == x and position.y == y then
                return entity
            end
        end
    end

    function ctx:move_actors(moves)
        for _, move in ipairs(moves) do
            self.values[move.actor][component.POSITION] = {
                level_id = move.level_id,
                x = move.x,
                y = move.y,
            }
        end
    end

    -- Fixed draws exercise lower duration bounds and make status assertions
    -- independent of unrelated random-stream order.
    function ctx:random(_, bound)
        harness.truthy(bound > 0, "random bound stays positive")
        return 0
    end

    -- Proportional armour uses a full-width draw; zero lets each weak cold
    -- point through without copying the production armour calculation.
    function ctx:random_u64()
        return 0, 0
    end

    function ctx:aut()
        return self.clock
    end

    function ctx:emit()
    end

    function ctx:signal()
    end

    function ctx:id(entity)
        return entity
    end

    return ctx
end

-- A source toxic cast damages the susceptible foe once immediately and
-- again on later actions, while the same-side ally stays untouched.
local function toxic_radiance()
    local ctx = context()
    local effect = effects.effect(spells.SPELL_OLGREBS_TOXIC_RADIANCE)
    local plan = effect.plan(ctx, caster, foe)

    harness.truthy(plan, "visible susceptible foe permits Radiance")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.truthy(ctx:has(caster, component.MONSTER_TOXIC_RADIANCE),
        "Radiance timer is saved on its caster")
    harness.equal(ctx:get(ally, component.HEALTH).current, 100,
        "an aligned monster is not irradiated")
    harness.truthy(ctx:get(foe, component.HEALTH).current < 100,
        "the cast causes an immediate poison hit")
    harness.falsy(effect.plan(ctx, caster, foe),
        "an active caster does not recast the aura")

    local before = ctx:get(foe, component.HEALTH).current

    poison_tick.update(ctx, caster, 10)
    harness.truthy(ctx:get(foe, component.HEALTH).current < before,
        "the next caster action produces another hit")
end

-- The existing player vortex component is actor-neutral, but a monster
-- retains its own cooldown after its saved storm has expired.
local function polar_vortex()
    local ctx = context()
    local effect = effects.effect(spells.SPELL_POLAR_VORTEX)

    -- The source tracer refuses an equal-strength ally beside one foe.
    -- Move the ally out of the storm so this cast is tactically sound.
    ctx.values[ally][component.POSITION].x = 21

    local plan = effect.plan(ctx, caster, foe)

    harness.truthy(plan, "vulnerable foe permits a hostile vortex")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.truthy(ctx:has(caster, zap_ids.component.POLAR_VORTEX),
        "monster uses the saved common storm component")
    harness.truthy(ctx:has(caster, component.ZAP_FLIGHT),
        "the storm lifts its caster")
    harness.falsy(effect.plan(ctx, caster, foe),
        "an active storm prevents recasting")

    local active = ctx:get(caster, zap_ids.component.POLAR_VORTEX)

    -- A mature, high-power wind ring makes the later tick observable even
    -- with the fixture's minimum random draws.
    active.started_aut = 0
    active.power = 100
    ctx:set(caster, zap_ids.component.POLAR_VORTEX, active)

    local health_before = ctx:get(foe, component.HEALTH).current

    vortex_tick.update(ctx, caster, 10)

    harness.truthy(ctx:get(foe, component.HEALTH).current <
        health_before, "a later storm ring damages its foe")
    harness.truthy(ctx:has(foe, component.ZAP_FLIGHT),
        "the wind grants its victim saved temporary flight")

    ctx.values[foe][component.POSITION].x = 20
    ctx.clock = ctx.clock + 50
    vortex_tick.update(ctx, caster, 50)

    harness.falsy(ctx:has(caster, zap_ids.component.POLAR_VORTEX),
        "the storm ends after its saved duration")
    harness.truthy(ctx:has(caster,
        component.MONSTER_VORTEX_COOLDOWN),
        "expired storm begins a saved cooldown")
    harness.falsy(effect.plan(ctx, caster, foe),
        "cooldown prevents immediate recasting")
end

-- Vortex resistance prevents cold damage, not physical wind rotation.
-- Tree form, conversely, cannot be lifted and is skipped altogether.
local function vortex_victim_exceptions()
    local immune = context()

    immune.values[ally][component.POSITION].x = 21
    immune.values[foe][component.ACTOR].kind_id =
        monsters.MONS_TWISTER
    immune:add(caster, zap_ids.component.POLAR_VORTEX, {
        remaining_aut = 30,
        started_aut = 0,
        power = 100,
    })

    vortex_tick.update(immune, caster, 10)

    harness.equal(immune:get(foe, component.HEALTH).current, 100,
        "vortex resistance prevents cold damage")

    local moved = immune:get(foe, component.POSITION)

    harness.truthy(moved.x ~= 6 or moved.y ~= 5,
        "vortex resistance does not anchor a monster")

    local tree = context()

    tree.values[ally][component.POSITION].x = 21
    tree.values[foe][component.POSITION].x = 20
    tree.values[player][component.POSITION].x = 6
    tree.values[player][component.POSITION].y = 5
    tree.values[player][component.PLAYER_FORM] = {
        form_id = form_ids.TREE,
        remaining_aut = 30,
        power = 0,
    }
    tree:add(caster, zap_ids.component.POLAR_VORTEX, {
        remaining_aut = 30,
        started_aut = 0,
        power = 100,
    })

    vortex_tick.update(tree, caster, 10)

    harness.equal(tree:get(player, component.HEALTH).current, 100,
        "flight-forbidden tree form takes no wind damage")
    harness.equal(tree:get(player, component.POSITION).x, 6,
        "flight-forbidden player remains in place")
    harness.falsy(tree:has(player, component.ZAP_FLIGHT),
        "flight-forbidden player gains no wind flight")
end

-- Source monster speed changes wind exposure but leaves the saved aura
-- duration on the baseline action clock.
local function vortex_speed()
    local ctx = context()
    local actor = ctx:get(caster, component.ACTOR)

    actor.speed = 5
    ctx:set(caster, component.ACTOR, actor)
    harness.equal(duration.action_aut(ctx, caster), 20,
        "slow monster wind pulse covers twenty aut")

    actor.speed = 20
    ctx:set(caster, component.ACTOR, actor)
    harness.equal(duration.action_aut(ctx, caster), 5,
        "fast monster wind pulse covers five aut")
end

-- Run both complete spell contracts in one domain test, avoiding copies of
-- their component schemas or catalog definitions.
function test.run()
    toxic_radiance()
    polar_vortex()
    vortex_victim_exceptions()
    vortex_speed()
end

return test
