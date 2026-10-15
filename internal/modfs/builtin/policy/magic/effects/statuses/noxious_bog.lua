-- Source: spl-damage.cc:find_bog_locations, cast_noxious_bog,
-- and actor_apply_toxic_bog.
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local time = require("constants.time")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local poison = require("policy.combat.monster_poison")
local brands = require("policy.combat.brands")
local player_health = require("policy.combat.player_health")
local causes = require("constants.damage_causes")
local player_resistance = require("policy.combat.player_resistance")
local flight = require("policy.combat.flight")
local range = require("policy.magic.range")
local terrain = require("policy.magic.effects.summons.terrain")

local bog = {}

local nonfloor = {
    [terrain_ids.DNGN_DEEP_WATER] = true,
    [terrain_ids.DNGN_SHALLOW_WATER] = true,
    [terrain_ids.DNGN_OPEN_SEA] = true,
    [terrain_ids.DNGN_LAVA] = true,
    [terrain_ids.DNGN_TOXIC_BOG] = true,
}

local function locations(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)
    local found = {}

    for dy = -reach, reach do
        for dx = -reach, reach do
            local x, y = origin.x + dx, origin.y + dy
            local feature = ctx:cell(origin.level_id, x, y)

            if feature and not nonfloor[feature] and
                ctx:walkable(origin.level_id, x, y) and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    x, y) then
                local walls = 0

                for neighbor_y = -1, 1 do
                    for neighbor_x = -1, 1 do
                        if neighbor_x ~= 0 or neighbor_y ~= 0 then
                            local nx, ny = x + neighbor_x, y + neighbor_y

                            if not ctx:visible(origin.level_id,
                                origin.x, origin.y, reach, nx, ny) or
                                not ctx:walkable(origin.level_id, nx, ny) then
                                walls = walls + 1
                            end
                        end
                    end
                end

                if walls <= 1 then
                    found[#found + 1] = { x = x, y = y }
                end
            end
        end
    end

    return found
end

function bog.prepare(ctx, player, spell)
    if #locations(ctx, player, spell) == 0 then
        return "There are no places for you to create a bog."
    end
end

function bog.cast(ctx, player, _, spell, power)
    local cells = locations(ctx, player, spell)
    local bound = math.floor(power / 10)
    local turns = 5 + (bound > 0 and ctx:random("spell", bound) or 0)
    local expires = ctx:aut() + turns * time.AUT_PER_TURN
    local origin = ctx:get(player, component.POSITION)

    for _, cell in ipairs(cells) do
        terrain.temporary(ctx, player, spells.SPELL_NOXIOUS_BOG,
            origin.level_id, cell.x, cell.y, terrain_ids.DNGN_TOXIC_BOG, expires)
    end

    local state = ctx:get(player, component.AREA_STATUS) or {
        corpse_rot_aut = 0,
        corpse_rot_power = 0,
        toxic_radiance_aut = 0,
        toxic_radiance_power = 0,
        noxious_bog_aut = 0,
    }
    state.noxious_bog_aut = state.noxious_bog_aut +
        turns * time.AUT_PER_TURN

    if ctx:has(player, component.AREA_STATUS) then
        ctx:set(player, component.AREA_STATUS, state)
    else
        ctx:add(player, component.AREA_STATUS, state)
    end

    ctx:emit("spell", "You spew toxic sludge!")
end

local function roll_damage(ctx)
    local total = 0

    for _ = 1, 4 do
        total = total + 1 + ctx:random("spell", 6)
    end

    return total
end

local function adjusted(raw, resistance)
    local resistible = math.floor(raw * 70 / 100)
    local solid = raw - resistible

    if resistance >= 3 then
        resistible = 0
    elseif resistance > 0 then
        resistible = math.floor(resistible /
            (2 + resistance * resistance))
    elseif resistance < 0 then
        resistible = math.floor(resistible * 3 / 2)
    end

    return solid + resistible
end

function bog.tick(ctx, actor, aut)
    local position = ctx:get(actor, component.POSITION)
    local health = ctx:get(actor, component.HEALTH)

    if not position or not health or health.current <= 0 or
        ctx:cell(position.level_id, position.x, position.y) ~= terrain_ids.DNGN_TOXIC_BOG then
        return
    end

    if flight.active(ctx, actor) then
        return
    end

    if actor == ctx:player() then
        local status = ctx:get(actor, component.AREA_STATUS)

        if status and status.noxious_bog_aut > 0 then
            return
        end

        local resistance = player_resistance.poison(ctx, actor)
        local amount = math.floor(adjusted(roll_damage(ctx), resistance) *
            math.max(1, aut) / time.AUT_PER_TURN)

        if amount > 0 then
            player_health.damage(ctx, actor, amount,
                false, nil, causes.CLOUD)
            brands.poison(ctx, resistance > 0 and 7 or 21,
                "toxic bog")
            ctx:emit("warning", "You fester in the toxic bog!")
        end

        return
    end

    local definition = catalog.get("monsters",
        ctx:get(actor, component.ACTOR).kind_id)

    if definition.id == monsters.MONS_FENSTRIDER_WITCH then
        return
    end

    local resistance = poison.resistance(definition)
    local amount = math.floor(adjusted(roll_damage(ctx), resistance) *
        math.max(1, aut) / time.AUT_PER_TURN)

    if amount > 0 then
        poison.apply(ctx, actor, definition,
            resistance > 0 and 7 or 21, ctx:player(), true)
        damage.apply(ctx, actor, amount)
        ctx:emit("spell", "The " .. definition.name ..
            " festers in the toxic bog!")
    end
end

return bog
