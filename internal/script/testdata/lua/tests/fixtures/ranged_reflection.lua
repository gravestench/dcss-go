local component = require("constants.component")
local ids = require("ids.items")
local monsters = require("ids.monsters")
local terrain = require("constants.terrain")
local jewellery = require("tests.fixtures.jewellery")

local fixture = {}

-- Build shooter, player, projectile, and optional gear on one ECS world so only reflection varies.
function fixture.scene(ctx, missile_id, with_reflector, monster_id,
    with_shield)
    local base, player = jewellery.player(ctx)
    local battle = setmetatable({}, { __index = base })
    local events = {}
    local signals = {}
    local shooter = ctx:create()
    local missile = ctx:create()
    local amulet

    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 20,
    })
    ctx:add(player, component.MAGIC, {
        current = 2,
        max = 2,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    ctx:add(shooter, component.ACTOR, {
        kind_id = monster_id or monsters.MONS_GOBLIN,
        speed = 10,
    })
    ctx:add(shooter, component.HEALTH, {
        current = 40,
        max = 40,
    })
    ctx:add(shooter, component.POSITION, {
        level_id = 1,
        x = 4,
        y = 1,
    })
    ctx:add(shooter, component.COMBAT, { shield_blocks = 0 })

    ctx:add(missile, component.ITEM, {
        kind_id = missile_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = missile_id == ids.MI_DART and "poisoned" or "",
    })
    ctx:add(missile, component.CARRIED_BY, { holder = shooter })
    ctx:add(missile, component.EQUIPPED, { slot = "missile" })

    if with_reflector then
        amulet = jewellery.carry(ctx, player, ids.AMU_REFLECTION)

        ctx:add(amulet, component.EQUIPPED, { slot = "amulet" })
    end

    if with_shield ~= false then
        local buckler = jewellery.carry(ctx, player, ids.ARM_BUCKLER)

        ctx:add(buckler, component.EQUIPPED, { slot = "shield" })
    end

    -- Attribute the incoming projectile to the fixture's monster shooter.
    function battle.actor()
        return shooter
    end

    -- Hold all terrain as floor so blocked paths do not confound reflection.
    function battle.cell()
        return terrain.DNGN_FLOOR
    end

    -- Keep trajectories clear while testing shield and return logic.
    function battle.projectile_clear()
        return true
    end

    -- Record combat text for ordering assertions without terminal services.
    function battle.emit(_, kind, message)
        events[#events + 1] = {
            kind = kind,
            text = message,
        }
    end

    -- Expose the captured message sequence after the shot resolves.
    function battle.events()
        return events
    end

    -- Capture player-kill credit from a lethal reflected projectile.
    function battle.signal(_, kind, target)
        signals[#signals + 1] = {
            kind = kind,
            target = target,
        }
    end

    -- Expose kill signals without querying live game systems.
    function battle.signals()
        return signals
    end

    return battle, player, shooter, missile, amulet
end

-- Script monster-spell draws for an inbound block followed by a return hit.
function fixture.slug_dart_block_then_return(battle)
    local draws = 0

    -- Preserve Slug Dart's draw sequence so the return path is tested after the first shield contest.
    function battle.random(_, stream, bound)
        if stream ~= "monster_spell" then
            return 0
        end

        draws = draws + 1

        if draws == 2 or draws == 3 or draws == 4 or
            draws == 7 or draws == 8 then
            return bound - 1
        end

        return 0
    end
end

-- Script both inbound and returned Slug Dart shield contests.
function fixture.slug_dart_block_twice(battle)
    local draws = 0

    -- Force a second shield contest on the rebound without changing unrelated RNG streams.
    function battle.random(_, stream, bound)
        if stream ~= "monster_spell" then
            return 0
        end

        draws = draws + 1

        if draws == 2 or draws == 3 or draws == 4 or draws == 5 then
            return bound - 1
        end

        return 0
    end
end

-- Use melee-stream draws to force a block and optionally a returned hit.
function fixture.block_then_return(battle, return_hits)
    local draws = 0

    -- Pin the shield roll positions; later values control the rebound without bypassing damage draws.
    function battle.random(_, stream, bound)
        if stream ~= "melee" then
            return 0
        end

        draws = draws + 1
        local value = 0

        -- The first seven melee draws produce an inbound shield block.
        -- The rebound then auto-hits and rolls its damage.
        if draws == 4 then
            value = math.min(50, bound - 1)
        elseif draws == 6 or draws == 7 then
            value = bound - 1
        elseif draws == 8 then
            value = bound - 1
        elseif draws == 12 and return_hits ~= false then
            value = math.min(1, bound - 1)
        elseif draws >= 14 then
            value = bound - 1
        end

        return value
    end
end

-- Equip the shooter to test whether self-directed reflections bypass its shield.
function fixture.enemy_shield(ctx, shooter)
    local shield = jewellery.carry(ctx, shooter, ids.ARM_BUCKLER)

    ctx:add(shield, component.EQUIPPED, { slot = "shield" })

    return shield
end

-- Equip a branded Sling so reflection can exercise launcher brand damage.
function fixture.launcher(ctx, shooter, brand)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = ids.WPN_SLING,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = brand,
    })
    ctx:add(entity, component.CARRIED_BY, { holder = shooter })
    ctx:add(entity, component.EQUIPPED, { slot = "weapon" })

    return entity
end

return fixture
