-- Lee's Rapid Deconstruction has one material rule for both player and
-- monster casters. A target's material determines direct damage, blast dice,
-- radius, and whether the center is part of the explosion.
-- Source: spl-damage.cc:setup_fragmentation_beam and cast_fragmentation.
local channels = require("constants.message_channels")
local component = require("constants.component")
local flavours = require("constants.beam_flavours")
local forms = require("constants.form_ids")
local materials = require("constants.fragment_material")
local monsters = require("ids.monsters")
local species = require("ids.species")
local terrain = require("constants.terrain")
local direct = require("policy.combat.monster_direct")
local explosion = require("policy.combat.explosion")
local impact = require("policy.combat.monster_area.impact")
local stasis = require("policy.magic.effects.statuses.monster_stasis")

local fragmentation = {}

-- spl-damage.cc:fraggable_monsters and fraggable_terrain.
local monster_material = {
    [monsters.MONS_TOENAIL_GOLEM] = materials.ROCK,
    [monsters.MONS_SALTLING] = materials.ROCK,
    [monsters.MONS_EARTH_ELEMENTAL] = materials.ROCK,
    [monsters.MONS_ROCKSLIME] = materials.ROCK,
    [monsters.MONS_USHABTI] = materials.ROCK,
    [monsters.MONS_STATUE] = materials.ROCK,
    [monsters.MONS_GARGOYLE] = materials.ROCK,
    [monsters.MONS_VV] = materials.ROCK,
    [monsters.MONS_IRON_ELEMENTAL] = materials.METAL,
    [monsters.MONS_IRON_GOLEM] = materials.METAL,
    [monsters.MONS_PEACEKEEPER] = materials.METAL,
    [monsters.MONS_WAR_GARGOYLE] = materials.METAL,
    [monsters.MONS_CRYSTAL_GUARDIAN] = materials.CRYSTAL,
    [monsters.MONS_CRYSTAL_ECHIDNA] = materials.CRYSTAL,
    [monsters.MONS_ORANGE_STATUE] = materials.CRYSTAL,
    [monsters.MONS_OBSIDIAN_STATUE] = materials.CRYSTAL,
    [monsters.MONS_ROXANNE] = materials.CRYSTAL,
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
    [terrain.DNGN_ROCK_WALL] = materials.ROCK,
    [terrain.DNGN_SLIMY_WALL] = materials.ROCK,
    [terrain.DNGN_STONE_WALL] = materials.ROCK,
    [terrain.DNGN_PERMAROCK_WALL] = materials.ROCK,
    [terrain.DNGN_CLEAR_ROCK_WALL] = materials.ROCK,
    [terrain.DNGN_CLEAR_STONE_WALL] = materials.ROCK,
    [terrain.DNGN_CLEAR_PERMAROCK_WALL] = materials.ROCK,
    [terrain.DNGN_ORCISH_IDOL] = materials.ROCK,
    [terrain.DNGN_GRANITE_STATUE] = materials.ROCK,
    [terrain.DNGN_PETRIFIED_TREE] = materials.ROCK,
    [terrain.DNGN_OPEN_DOOR] = materials.ROCK,
    [terrain.DNGN_CLOSED_DOOR] = materials.ROCK,
    [terrain.DNGN_METAL_WALL] = materials.METAL,
    [terrain.DNGN_GRATE] = materials.METAL,
    [terrain.DNGN_CRYSTAL_WALL] = materials.CRYSTAL,
}

-- Read the monster material only while the target is alive and still has an actor record.
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
        return materials.ROCK
    end

    if icy[kind] then
        return materials.ICE
    end

    if skeletal[kind] then
        return materials.ROCK
    end

    return nil
end

-- Choose player material from current form and species for self-targeted destruction.
local function player_profile(ctx, player)
    local choice = ctx:get(player, component.PLAYER)
    local form = ctx:get(player, component.PLAYER_FORM)

    if form and form.form_id == forms.ICE_BEAST then
        return materials.ICE
    end

    if form and form.form_id == forms.STATUE then
        return materials.ROCK
    end

    if choice and choice.species_id == species.SP_GARGOYLE then
        return materials.GARGOYLE
    end

    return nil
end

-- Prefer an occupant material at the impact cell before checking terrain material.
function fragmentation.profile(ctx, level, x, y)
    local target = ctx:actor_at(level, x, y)
    local player = ctx:player()

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

-- Callers select a saved stream for their casting domain. Direct shattering
-- bypasses AC, unlike the surrounding fragment blast.
local function roll(ctx, stream, count, sides)
    local total = 0

    for _ = 1, count do
        total = total + 1 + ctx:random(stream, sides)
    end

    return total
end

-- A caster can shatter an actor or feature. Beam fragment armour is triple
-- AC; ice is 40 percent resistible. The shared impact owner applies both
-- defenses and credits HP loss to the actual caster.
function fragmentation.resolve(ctx, caster, level_id, x, y, power, stream)
    local material, direct_hit, target, hit_center =
        fragmentation.profile(ctx, level_id, x, y)

    if not material then
        error("Lee's Rapid Deconstruction lost its prepared target")
    end

    -- base_fragmentation_damage is 3d(5 + power/5). Metal and crystal
    -- add a die; crystal also adds a blast ring. Gargoyles lose a die.
    local sides = 5 + math.floor(power / 5)
    local count = 3

    if material == materials.METAL or material == materials.CRYSTAL then
        count = count + 1
    elseif material == materials.GARGOYLE then
        count = count - 1
    end

    if direct_hit then
        direct.damage(ctx, caster, target,
            roll(ctx, stream, count, sides))
    end

    local beam = {
        flavour = material == materials.ICE and
            flavours.BEAM_ICE or flavours.BEAM_FRAG,
        rng_stream = stream,
    }
    local radius = material == materials.CRYSTAL and 2 or 1
    local name = material == materials.ICE and "icy blast" or "fragment blast"

    ctx:emit(channels.SPELL, "The " .. name .. " explodes!")

    for _, cell in ipairs(explosion.cells(ctx, level_id,
        x, y, radius, not ctx:walkable(level_id, x, y))) do
        if hit_center or cell.x ~= x or cell.y ~= y then
            local victim = ctx:actor_at(level_id, cell.x, cell.y)

            if victim then
                impact.hit(ctx, caster, victim,
                    roll(ctx, stream, count, sides), beam)
            end
        end
    end
end

return fragmentation
