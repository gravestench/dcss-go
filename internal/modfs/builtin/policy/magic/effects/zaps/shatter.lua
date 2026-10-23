local component = require("constants.component")
local spells = require("ids.spells")
local monsters = require("ids.monsters")
local terrain = require("constants.terrain")
local defense = require("policy.combat.monster_defense")
local damage = require("policy.magic.damage")
local fragments = require("policy.combat.monster_area.fragmentation")
local registry = require("policy.magic.effects.registry")
local attack_conduct = require("policy.religion.conduct.attack")

local shatter = {}

-- spl-damage.cc:terrain_shatter_chances. All represented door features share
-- the source 100% chance; permanent rock is intentionally absent.
local terrain_chance = {
    [terrain.DNGN_CLOSED_DOOR] = 100,
    [terrain.DNGN_OPEN_DOOR] = 100,
    [terrain.DNGN_GRATE] = 100,
    [terrain.DNGN_ORCISH_IDOL] = 100,
    [terrain.DNGN_GRANITE_STATUE] = 100,
    [terrain.DNGN_CLEAR_ROCK_WALL] = 33,
    [terrain.DNGN_ROCK_WALL] = 33,
    [terrain.DNGN_SLIMY_WALL] = 33,
    [terrain.DNGN_CRYSTAL_WALL] = 33,
    [terrain.DNGN_TREE] = 33,
    [terrain.DNGN_MANGROVE] = 33,
    [terrain.DNGN_DEMONIC_TREE] = 33,
    [terrain.DNGN_CLEAR_STONE_WALL] = 25,
    [terrain.DNGN_STONE_WALL] = 25,
    [terrain.DNGN_METAL_WALL] = 15,
}

-- Treat absent flag lists as empty when excluding conjured Shatter targets.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Choose fragment dice from monster material rather than using one damage profile for all bodies.
local function dice(ctx, monster, definition)
    local kind = definition.id

    if fragments.explicit_monster_material(kind) then
        return 6
    end

    if has_flag(definition, "M_INSUBSTANTIAL") then
        return 1
    end

    if fragments.monster_profile(ctx, monster) then
        return 6
    end

    if has_flag(definition, "M_FLIES") or
        definition.genus_id == monsters.MONS_JELLY or
        definition.genus_id == monsters.MONS_FLOATING_EYE or
        definition.genus_id == monsters.MONS_GLOWING_ORANGE_BRAIN then
        return 1
    end

    return 3
end

-- Skip dead or conjured actors before material-specific Shatter damage is rolled.
local function hurt(ctx, monster, power)
    local definition, health = damage.monster(ctx, monster)

    if not definition or health.current <= 0 or
        has_flag(definition, "M_CONJURED") then
        return
    end

    attack_conduct.report(ctx, monster, definition)

    local sides = 5 + math.floor(math.min(power, 200) / 3)
    local amount = 0

    for _ = 1, dice(ctx, monster, definition) do
        amount = amount + 1 + ctx:random("spell", sides)
    end

    local ac = defense.armour(ctx, monster, definition)

    if ac > 0 then
        amount = math.max(0, amount - ctx:random("spell", ac))
    end

    damage.apply(ctx, monster, amount)
end

-- Example: A crystal monster takes fragment dice based on crystal material rather than generic flesh.
-- Walk rings outward so newly broken terrain can expose farther actors during the same cast.
function shatter.resolve(ctx, player, _, _, power)
    local origin = ctx:get(player, component.POSITION)
    local level = origin.level_id
    local broken = 0

    ctx:emit("spell", "The dungeon rumbles!")

    -- spl-damage.cc:cast_shatter checks LOS_SOLID on every visited cell.
    -- Rechecking after each mutation lets a newly broken wall reveal cells
    -- farther out in the same cast.
    for radius = 1, 7 do
        for dy = -radius, radius do
            for dx = -radius, radius do
                if math.max(math.abs(dx), math.abs(dy)) == radius then
                    local x = origin.x + dx
                    local y = origin.y + dy

                    if ctx:cell(level, x, y) and
                        ctx:visible(level, origin.x, origin.y, 7, x, y) then
                        local target = ctx:actor_at(level, x, y)

                        if target and target ~= player then
                            hurt(ctx, target, power)
                        end

                        local chance = terrain_chance[ctx:cell(level, x, y)]

                        if chance and ctx:random("spell", 100) < chance then
                            ctx:set_cell(level, x, y, terrain.DNGN_FLOOR)
                            broken = broken + 1
                        end
                    end
                end
            end
        end
    end

    if broken > 0 then
        ctx:emit("spell", "Ka-crash!")
    end
end

registry.add(spells.SPELL_SHATTER, shatter)

return shatter
