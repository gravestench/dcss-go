-- A monster Orb of Destruction must use the same saved homing actor as the
-- player spell, with its own spell power and attributed player damage.
local catalog = require("policy.catalog")
local component = require("constants.component")
local damage = require("policy.magic.damage")
local effect = require("policy.combat.monster_spells.iood")
local explosion = require("policy.combat.explosion")
local harness = require("tests.harness")
local iood = require("policy.magic.effects.zaps.iood")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local player_health = require("policy.combat.player_health")
local summons = require("policy.magic.effects.summons.common")
local zap_ids = require("policy.magic.effects.zaps.ids")
local rng_streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local expiry = require("systems.magic_summon_expiry")

local test = {}
local caster = 11
local foe = 22
local orb = 33

-- A four-cell open corridor lets the orb leave its owner and later collide
-- with the player. The test patches only entity creation and final HP sinks.
local function context()
    local positions = {
        [caster] = {
            level_id = 1,
            x = 0,
            y = 0,
        },

        [foe] = {
            level_id = 1,
            x = 4,
            y = 0,
        },
    }
    local values = {}
    local draws = {}
    local ctx = {}

    function ctx:player()
        return foe
    end

    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.ACTOR and entity == caster then
            return { kind_id = monsters.MONS_ORC_WIZARD }
        end

        if id == component.HEALTH then
            if entity == caster and self.dead_caster then
                return { current = 0, max = 100 }
            end

            return { current = 100, max = 100 }
        end

        return values[entity] and values[entity][id]
    end

    function ctx:has(entity, id)
        if entity == foe and id == component.PLAYER then
            return true
        end

        if id == component.ACTOR and (entity == caster or entity == orb) then
            return true
        end

        return values[entity] and values[entity][id] ~= nil or false
    end

    function ctx:query(components)
        if components[1] == component.SUMMON then
            return { orb }
        end

        return {}
    end

    function ctx:id(entity)
        return entity
    end

    function ctx:add(entity, id, value)
        values[entity] = values[entity] or {}
        values[entity][id] = value
    end

    function ctx:set(entity, id, value)
        self:add(entity, id, value)
    end

    function ctx:random(stream, bound)
        draws[#draws + 1] = stream
        harness.truthy(bound > 0, "orb random draws have positive bounds")

        return 0
    end

    function ctx:aut()
        return 0
    end

    function ctx:visible()
        return true
    end

    function ctx:cell()
        return terrain.DNGN_FLOOR
    end

    function ctx:walkable()
        return true
    end

    function ctx:actor_at(_, x, y)
        if x == 4 and y == 0 then
            return foe
        end

        return nil
    end

    function ctx:move_actor(entity, level_id, x, y)
        positions[entity] = {
            level_id = level_id,
            x = x,
            y = y,
        }
    end

    function ctx:emit()
    end

    return ctx, positions, values, draws
end

-- The cast makes a monster-owned orb, and a later tick credits damage to
-- that monster instead of treating the player as the orb owner.
function test.run()
    local previous = {
        spawn = summons.spawn,
        expire = summons.expire,
        cells = explosion.cells,
        armour = damage.player_armour,
        player_damage = player_health.damage,
    }
    local ctx, positions, values, draws = context()
    local spawned
    local hit

    summons.spawn = function(_, owner, _, _, _, _, options)
        spawned = {
            owner = owner,
            options = options,
        }
        positions[orb] = {
            level_id = 1,
            x = options.exact.x,
            y = options.exact.y,
        }
        values[orb] = {
            [component.SUMMON] = {
                owner = owner,
                source_id = spells.SPELL_IOOD,
                expires_aut = options.expires_aut,
            },
        }

        return orb
    end

    summons.expire = function()
    end

    explosion.cells = function(_, _, x, y)
        return { { x = x, y = y } }
    end

    damage.player_armour = function(_, _, raw)
        return raw
    end

    player_health.damage = function(_, victim, amount, _, source)
        hit = {
            victim = victim,
            amount = amount,
            source = source,
        }
    end

    local plan = effect.plan(ctx, caster, foe)

    harness.truthy(plan, "a visible distant foe offers the orb")
    effect.resolve(ctx, caster, foe, nil, plan)

    local state = ctx:get(orb, zap_ids.component.IOOD)
    local definition = catalog.get("monsters",
        monsters.MONS_ORC_WIZARD)

    harness.equal(spawned.owner, caster,
        "the homing actor belongs to the monster")
    harness.equal(state.target, foe,
        "the saved orb remembers its selected foe")
    harness.equal(state.power, definition.hd * 8,
        "monster spell HD uses the source IOOD power factor")
    harness.equal(draws[1], rng_streams.MONSTER_SPELL,
        "monster launch uses the monster spell RNG stream")

    -- Set a saved near-contact state to test the real homing tick and
    -- explosion without depending on the earlier travel path.
    positions[orb].x = 3
    positions[orb].y = 0
    state.x = 3
    state.y = 0
    state.vx = 1
    state.vy = 0
    state.distance = 3
    ctx:set(orb, zap_ids.component.IOOD, state)
    iood.tick(ctx, orb)

    harness.equal(hit.victim, foe,
        "the blast hits the player in its contact cell")
    harness.equal(hit.source, caster,
        "the monster receives the orb's damage attribution")

    -- Death cleanup removes the caster entity. The finite orb must retain
    -- a live owner link and therefore transfers ownership to itself.
    ctx.dead_caster = true
    expiry.update(ctx, foe)

    harness.equal(ctx:get(orb, component.SUMMON).owner, orb,
        "a monster orb survives its caster's death and remains saveable")

    summons.spawn = previous.spawn
    summons.expire = previous.expire
    explosion.cells = previous.cells
    damage.player_armour = previous.armour
    player_health.damage = previous.player_damage
end

return test
