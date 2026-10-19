local spells = require("ids.spells")
local component = require("constants.component")
local targets = require("policy.ai.targets")
local terrain_ids = require("constants.terrain")
local catalog = require("policy.catalog")
local defense = require("policy.combat.monster_defense")
local common = require("policy.magic.effects.translocation.common")
local damage = require("policy.magic.damage")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local ramparts = {}
local walls = {
    [terrain_ids.DNGN_ROCK_WALL] = true,
    [terrain_ids.DNGN_STONE_WALL] = true,
    [terrain_ids.DNGN_METAL_WALL] = true,
    [terrain_ids.DNGN_CRYSTAL_WALL] = true,
    [terrain_ids.DNGN_PERMAROCK_WALL] = true,
    [terrain_ids.DNGN_CLEAR_ROCK_WALL] = true,
    [terrain_ids.DNGN_CLEAR_STONE_WALL] = true,
    [terrain_ids.DNGN_CLEAR_PERMAROCK_WALL] = true,
    [terrain_ids.DNGN_SLIMY_WALL] = true,
}

-- Example: ramparts.prepare(ctx, player, spell) requires reachable walls near
-- the caster before it spends a turn creating frozen wall markers.
local function find_walls(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)
    local found = {}

    for dy = -reach, reach do
        for dx = -reach, reach do
            local x, y = origin.x + dx, origin.y + dy

            if (dx ~= 0 or dy ~= 0) and
                walls[ctx:cell(origin.level_id, x, y)] then
                local ray = trajectory.to_target(ctx, origin.level_id,
                    origin.x, origin.y, x, y,
                    math.max(math.abs(dx), math.abs(dy)))

                if ray.blocked_x == x and ray.blocked_y == y then
                    found[#found + 1] = { x = x, y = y }
                end
            end
        end
    end

    return found
end

-- Movement and timeout share cleanup so no frozen marker remains active after
-- the caster leaves its original cell.
function ramparts.end_effect(ctx, player, moved)
    for _, marker in ipairs(ctx:query({ component.FROZEN_WALL })) do
        local state = ctx:get(marker, component.FROZEN_WALL)

        if state.owner == player then
            ctx:destroy(marker)
        end
    end

    ctx:remove(player, component.FROZEN_RAMPARTS)
    ctx:emit("duration", moved and
        "The frozen ramparts melt away as you move." or
        "The frozen ramparts melt away.")
end

-- A monster takes cold damage only while adjacent to one of this caster's
-- active frozen walls.
local function icy_neighbor(ctx, player, position)
    for _, marker in ipairs(ctx:query({ component.FROZEN_WALL })) do
        local wall = ctx:get(marker, component.FROZEN_WALL)

        if wall.owner == player and wall.level_id == position.level_id and
            math.max(math.abs(wall.x - position.x),
                math.abs(wall.y - position.y)) <= 1 then
            return true
        end
    end

    return false
end

-- Frozen wall markers damage adjacent monsters while the caster's rampart duration remains active.
function ramparts.tick(ctx, actor, aut)
    local player = ctx:player()
    local state = ctx:get(player, component.FROZEN_RAMPARTS)

    if not state then
        return
    end

    if actor == player then
        local position = ctx:get(player, component.POSITION)

        if position.level_id ~= state.level_id or
            position.x ~= state.origin_x or position.y ~= state.origin_y then
            ramparts.end_effect(ctx, player, true)
            return
        end

        state.remaining_aut = math.max(0, state.remaining_aut - aut)

        if state.remaining_aut == 0 then
            ramparts.end_effect(ctx, player, false)
        else
            ctx:set(player, component.FROZEN_RAMPARTS, state)
        end

        return
    end

    if not ctx:has(actor, component.AI) or
        not targets.enemy(ctx, player, actor) then
        return
    end

    local position = ctx:get(actor, component.POSITION)
    local health = ctx:get(actor, component.HEALTH)

    if not position or not health or health.current <= 0 or
        not icy_neighbor(ctx, player, position) then
        return
    end

    local definition = catalog.get("monsters",
        ctx:get(actor, component.ACTOR).kind_id)
    local die_size = 1 + math.floor(state.power * 3 / 10)
    local raw = 1 + ctx:random("spell", math.max(1, die_size))
    local ac = defense.armour(ctx, actor, definition)
    local after_ac = math.max(0, raw - ctx:random("spell", ac + 1))
    local amount = damage.elemental(after_ac, definition, "MR_RES_COLD")
    amount = math.floor((amount * aut + ctx:random("spell", 10)) / 10)
    damage.apply(ctx, actor, amount)
    ctx:emit("spell", "The wall freezes the " .. definition.name .. "!")
end

-- Source: spl-damage.cc:cast_frozen_ramparts and terrain.cc:ice_wall_damage.
function ramparts.prepare(ctx, player, spell)
    if ctx:has(player, component.FROZEN_RAMPARTS) then
        return "You cannot sustain more frozen ramparts right now."
    end

    if #find_walls(ctx, player, spell) == 0 then
        return "There are no walls around you to affect."
    end
end

-- Save the caster's origin and one duration for every wall marker so movement ends the whole effect.
function ramparts.resolve(ctx, player, _, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local lower = 40 + power
    local upper = 80 + math.floor(power * 3 / 2)
    local turns = lower + ctx:random("spell", upper - lower + 1)

    ctx:add(player, component.FROZEN_RAMPARTS, {
        level_id = origin.level_id,
        origin_x = origin.x,
        origin_y = origin.y,
        power = power,
        remaining_aut = turns,
    })

    for _, wall in ipairs(find_walls(ctx, player, spell)) do
        local marker = ctx:create()
        ctx:add(marker, component.FROZEN_WALL, {
            owner = player,
            level_id = origin.level_id,
            x = wall.x,
            y = wall.y,
        })
    end

    ctx:emit("spell", "The walls around you are covered in ice.")
end

registry.add(spells.SPELL_FROZEN_RAMPARTS, {
    prepare = ramparts.prepare,

    resolve = ramparts.resolve,
})

return ramparts
