local component = require("constants.component")
local spells = require("ids.spells")
local monsters = require("ids.monsters")
local terrain = require("constants.terrain")
local damage = require("policy.magic.damage")
local explosion = require("policy.combat.explosion")
local explosive = require("policy.magic.effects.zaps.explosive")
local player_health = require("policy.combat.player_health")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local stasis = require("policy.magic.effects.statuses.monster_stasis")

local lrd = {}

-- spl-damage.cc:fraggable_monsters and fraggable_terrain.
local monster_material = {
    [monsters.MONS_TOENAIL_GOLEM] = "rock",
    [monsters.MONS_SALTLING] = "rock",
    [monsters.MONS_EARTH_ELEMENTAL] = "rock",
    [monsters.MONS_ROCKSLIME] = "rock",
    [monsters.MONS_USHABTI] = "rock",
    [monsters.MONS_STATUE] = "rock",
    [monsters.MONS_GARGOYLE] = "rock",
    [monsters.MONS_VV] = "rock",
    [monsters.MONS_IRON_ELEMENTAL] = "metal",
    [monsters.MONS_IRON_GOLEM] = "metal",
    [monsters.MONS_PEACEKEEPER] = "metal",
    [monsters.MONS_WAR_GARGOYLE] = "metal",
    [monsters.MONS_CRYSTAL_GUARDIAN] = "crystal",
    [monsters.MONS_CRYSTAL_ECHIDNA] = "crystal",
    [monsters.MONS_ORANGE_STATUE] = "crystal",
    [monsters.MONS_OBSIDIAN_STATUE] = "crystal",
    [monsters.MONS_ROXANNE] = "crystal",
}

local icy = {
    [monsters.MONS_ICE_BEAST] = true,
    [monsters.MONS_SIMULACRUM] = true,
    [monsters.MONS_ICE_STATUE] = true,
    [monsters.MONS_BLOCK_OF_ICE] = true,
    [monsters.MONS_NARGUN] = true,
}

local skeletal = {
    [monsters.MONS_SKELETON] = true,
    [monsters.MONS_BONE_DRAGON] = true,
    [monsters.MONS_SKELETAL_WARRIOR] = true,
    [monsters.MONS_ANCIENT_CHAMPION] = true,
    [monsters.MONS_REVENANT] = true,
    [monsters.MONS_FLYING_SKULL] = true,
    [monsters.MONS_CURSE_SKULL] = true,
    [monsters.MONS_MURRAY] = true,
}

local terrain_material = {
    [terrain.DNGN_ROCK_WALL] = "rock",
    [terrain.DNGN_SLIMY_WALL] = "rock",
    [terrain.DNGN_STONE_WALL] = "rock",
    [terrain.DNGN_PERMAROCK_WALL] = "rock",
    [terrain.DNGN_CLEAR_ROCK_WALL] = "rock",
    [terrain.DNGN_CLEAR_STONE_WALL] = "rock",
    [terrain.DNGN_CLEAR_PERMAROCK_WALL] = "rock",
    [terrain.DNGN_ORCISH_IDOL] = "rock",
    [terrain.DNGN_GRANITE_STATUE] = "rock",
    [terrain.DNGN_PETRIFIED_TREE] = "rock",
    [terrain.DNGN_OPEN_DOOR] = "rock",
    [terrain.DNGN_CLOSED_DOOR] = "rock",
    [terrain.DNGN_METAL_WALL] = "metal",
    [terrain.DNGN_GRATE] = "metal",
    [terrain.DNGN_CRYSTAL_WALL] = "crystal",
}

local function monster_profile(ctx, target)
    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return nil
    end

    local kind = actor.kind_id

    if monster_material[kind] then
        return monster_material[kind]
    end

    if stasis.petrifying(ctx, target) or stasis.petrified(ctx, target) then
        return "rock"
    end

    if icy[kind] then
        return "ice"
    end

    if skeletal[kind] then
        return "rock"
    end

    return nil
end

local function player_profile(ctx, player)
    local choice = ctx:get(player, "character.choice")
    local form = ctx:get(player, component.PLAYER_FORM)

    if form and form.form_id == "ice_beast" then
        return "ice"
    end

    if form and form.form_id == "statue" then
        return "rock"
    end

    if choice and choice.species_id == "SP_GARGOYLE" then
        return "gargoyle"
    end

    return nil
end

local function profile(ctx, player, level, x, y)
    local target = ctx:actor_at(level, x, y)

    if target == player then
        local material = player_profile(ctx, player)

        if material then
            return material, true, target, false
        end
    elseif target then
        local material = monster_profile(ctx, target)

        if material then
            return material, true, target, false
        end
    end

    local material = terrain_material[ctx:cell(level, x, y)]

    if material then
        return material, false, target, ctx:walkable(level, x, y)
    end

    return nil
end

local function target_cell(ctx, player, dx, dy)
    local origin = ctx:get(player, component.POSITION)

    return origin, origin.x + dx, origin.y + dy
end

function lrd.prepare(ctx, player, spell, dx, dy)
    local origin, x, y = target_cell(ctx, player, dx, dy)
    local reach = range.for_spell(ctx, player, spell)

    if math.max(math.abs(dx), math.abs(dy)) > reach or
        not ctx:visible(origin.level_id, origin.x, origin.y, reach, x, y) or
        not profile(ctx, player, origin.level_id, x, y) then
        return "You can't deconstruct that!"
    end
end

local function roll(ctx, count, sides)
    local total = 0

    for _ = 1, count do
        total = total + 1 + ctx:random("spell", sides)
    end

    return total
end

function lrd.resolve(ctx, player, intent, _, power)
    local origin, x, y = target_cell(ctx, player, intent.dx, intent.dy)
    local material, direct, target, hit_center =
        profile(ctx, player, origin.level_id, x, y)

    if not material then
        error("Lee's Rapid Deconstruction lost its prepared target")
    end

    -- base_fragmentation_damage is 3d(5 + power/5). Metal and crystal
    -- add a die; crystal also adds a blast ring. Gargoyles lose a die.
    local sides = 5 + math.floor(math.min(power, 200) / 5)
    local count = 3

    if material == "metal" or material == "crystal" then
        count = count + 1
    elseif material == "gargoyle" then
        count = count - 1
    end

    if direct then
        local amount = roll(ctx, count, sides)

        if target == player then
            player_health.damage(ctx, player, amount)
        else
            damage.apply(ctx, target, amount)
        end
    end

    local spec = {
        name = material == "ice" and "icy blast" or "fragment blast",
        element = material == "ice" and "MR_RES_COLD" or nil,
        resistible_fraction = material == "ice" and 40 or nil,
        damage = { kind = "fixed", count = count, sides = sides },
    }
    local radius = material == "crystal" and 2 or 1

    ctx:emit("spell", "The " .. spec.name .. " explodes!")

    for _, cell in ipairs(explosion.cells(ctx, origin.level_id,
        x, y, radius, not ctx:walkable(origin.level_id, x, y))) do
        if hit_center or cell.x ~= x or cell.y ~= y then
            local victim = ctx:actor_at(origin.level_id, cell.x, cell.y)

            if victim then
                explosive.hurt(ctx, player, victim, spec, power)
            end
        end
    end
end

lrd.monster_material = monster_material
lrd.icy = icy
lrd.skeletal = skeletal

registry.add(spells.SPELL_LRD, lrd)

return lrd
