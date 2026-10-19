-- Doom Howl belongs to the player after one unsummoned hound has cast it.
-- The fixture exercises that saved handoff and the later hostile arrivals.
local component = require("constants.component")
local clouds = require("policy.clouds.placement")
local effect = require("policy.combat.monster_spells.doom_howl")
local factory = require("policy.population.factory")
local habitat = require("policy.combat.monster_habitat")
local harness = require("tests.harness")
local ids = require("policy.combat.monster_doom_howl.ids")
local monsters = require("ids.monsters")
local target_kind = require("constants.target_kind")

local test = {}
local caster = 11
local player = 22
local called = 33

-- The real component IDs cross the cast and timed-system boundary. Fixed
-- draws choose the source's shortest duration and first call interval.
local function context()
    local positions = {
        [caster] = {
            level_id = 1,
            x = 1,
            y = 1,
        },

        [player] = {
            level_id = 1,
            x = 4,
            y = 4,
        },
    }
    local values = {}
    local messages = {}
    local ctx = {}

    function ctx:player()
        return player
    end

    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        return values[entity] and values[entity][id]
    end

    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    function ctx:add(entity, id, value)
        values[entity] = values[entity] or {}
        values[entity][id] = value
    end

    function ctx:set(entity, id, value)
        self:add(entity, id, value)
    end

    function ctx:remove(entity, id)
        values[entity][id] = nil
    end

    function ctx:actor_at()
        return nil
    end

    function ctx:random(_, bound)
        harness.truthy(bound > 0, "all source draws have a bound")

        return 0
    end

    function ctx:aut()
        return 0
    end

    function ctx:emit(_, message)
        messages[#messages + 1] = message
    end

    return ctx, messages
end

-- A hound gets one cast; each 20-aut interval then calls a hostile beast
-- next to the player. The timer and one-use marker both live in ECS.
function test.run()
    local old_spawn = factory.spawn
    local old_habitat = habitat.kind_at
    local old_cloud = clouds.place
    local ctx, messages = context()
    local arrivals = {}

    habitat.kind_at = function()
        return true
    end

    factory.spawn = function(_, kind_id, level_id, x, y, options)
        arrivals[#arrivals + 1] = {
            kind_id = kind_id,
            level_id = level_id,
            x = x,
            y = y,
            options = options,
        }

        return called
    end

    clouds.place = function()
        return true
    end

    local plan = effect.plan(ctx, caster, player)

    harness.equal(plan.kind, target_kind.ENTITY,
        "Doom Howl keeps the player as its selected foe")
    effect.resolve(ctx, caster, player, nil, plan)

    local state = ctx:get(player, ids.PLAYER_DOOM_HOWL)

    harness.equal(state.remaining_aut, 120,
        "the first source duration draw is 120 aut")
    harness.truthy(ctx:has(caster, ids.MONSTER_DOOM_HOWLED),
        "the casting hound cannot howl again")
    harness.falsy(effect.plan(ctx, caster, player),
        "the one-use marker rejects a second cast")

    effect.tick(ctx, player, 20)

    harness.equal(#arrivals, 1,
        "the first interval calls one beast")
    harness.equal(arrivals[1].kind_id, monsters.MONS_BONE_DRAGON,
        "the source five-beast pool starts with bone dragon")
    harness.equal(arrivals[1].options.attitude, "hostile",
        "called beasts are hostile regardless of the original hound")
    harness.equal(ctx:get(called,
        component.SUMMON_HAUNTING).target, player,
        "a called beast pursues the player")
    harness.equal(ctx:get(called, ids.ARRIVAL).created_aut, 0,
        "the permanent arrival has its own saved origin")

    effect.tick(ctx, player, 100)

    harness.falsy(ctx:has(player, ids.PLAYER_DOOM_HOWL),
        "the howl state leaves ECS when its duration ends")
    harness.truthy(#messages > 0,
        "the cast and expiration explain the effect to the player")

    factory.spawn = old_spawn
    habitat.kind_at = old_habitat
    clouds.place = old_cloud
end

return test
