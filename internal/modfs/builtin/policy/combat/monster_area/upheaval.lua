-- Upheaval and Eruption strike a selected cell and each non-solid
-- neighbor separately. Upheaval chooses lava, ice, air, or fragments;
-- Eruption fixes lava. Both may leave source terrain or storm clouds.
-- Source: mon-cast.cc:_mons_upheaval.
-- Example: upheaval.resolve(ctx, caster, plan, false) always uses lava.
local channels = require("constants.message_channels")
local component = require("constants.component")
local clouds = require("ids.clouds")
local decision = require("policy.combat.monster_area.decision")
local flavours = require("constants.beam_flavours")
local impact = require("policy.combat.monster_area.impact")
local placement = require("policy.clouds.placement")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")
local temporary = require("policy.world.temporary_terrain")

local upheaval = {}
local RANGE = 7
local FOE_RATIO_MIN = 20
local FOE_RATIO_SPAN = 11
local SIDES = 24
local DICE = 3

local variants = {
    flavours.BEAM_LAVA,
    flavours.BEAM_ICE,
    flavours.BEAM_AIR,
    flavours.BEAM_FRAG,
}

local messages = {
    "Magma suddenly erupts from the ground!",
    "A blizzard blasts the area with ice!",
    "A storm cloud blasts the area with cutting wind!",
    "The ground shakes violently, spewing rubble!",
}

local solid = {
    [terrain.DNGN_ROCK_WALL] = true,
    [terrain.DNGN_STONE_WALL] = true,
    [terrain.DNGN_PERMAROCK_WALL] = true,
    [terrain.DNGN_CLEAR_ROCK_WALL] = true,
    [terrain.DNGN_CLEAR_STONE_WALL] = true,
    [terrain.DNGN_CLEAR_PERMAROCK_WALL] = true,
    [terrain.DNGN_METAL_WALL] = true,
    [terrain.DNGN_CRYSTAL_WALL] = true,
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_CLOSED_DOOR] = true,
    [terrain.DNGN_DEMONIC_TREE] = true,
    [terrain.DNGN_GRANITE_STATUE] = true,
    [terrain.DNGN_ORCISH_IDOL] = true,
    [terrain.DNGN_PETRIFIED_TREE] = true,
    [terrain.DNGN_SLIMY_WALL] = true,
}

-- Source adjacent_iterator ignores solid terrain but does not require the
-- caster to walk on the cell; lava and deep water remain valid strike cells.
local function affected_cells(ctx, level_id, x, y)
    local cells = {
        {
            level_id = level_id,
            x = x,
            y = y,
        },
    }

    for cell_y = y - 1, y + 1 do
        for cell_x = x - 1, x + 1 do
            local feature = ctx:cell(level_id, cell_x, cell_y)

            if (cell_x ~= x or cell_y ~= y) and
                feature and not solid[feature] then
                cells[#cells + 1] = {
                    level_id = level_id,
                    x = cell_x,
                    y = cell_y,
                }
            end
        end
    end

    return cells
end

-- The source shuffles affected cells before sequential damage and terrain
-- changes, so no fixed coordinate gets a permanent first-hit advantage.
local function shuffle(ctx, cells)
    for index = #cells, 2, -1 do
        local chosen = ctx:random(streams.MONSTER_SPELL, index) + 1

        cells[index], cells[chosen] = cells[chosen], cells[index]
    end
end

-- Planning values every current occupant but never draws damage dice.
-- The source's low foe ratio lets an upheaval accept some collateral risk.
function upheaval.plan(ctx, caster, foe)
    local origin = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)

    if not origin or not destination or
        origin.level_id ~= destination.level_id then
        return nil
    end

    local distance = math.max(
        math.abs(destination.x - origin.x),
        math.abs(destination.y - origin.y))

    if distance > RANGE or not ctx:visible(origin.level_id,
        origin.x, origin.y, RANGE,
        destination.x, destination.y) then
        return nil
    end

    local victims = {}

    for _, cell in ipairs(affected_cells(ctx,
        destination.level_id, destination.x, destination.y)) do
        local victim = ctx:actor_at(cell.level_id, cell.x, cell.y)

        if victim then
            local health = ctx:get(victim, component.HEALTH)

            if health and health.current > 0 then
                victims[#victims + 1] = victim
            end
        end
    end

    local ratio = FOE_RATIO_MIN +
        ctx:random(streams.MONSTER_SPELL, FOE_RATIO_SPAN)

    if not decision.accept(ctx, caster, victims, ratio) then
        return nil
    end

    return {
        kind = target_kind.CELL,
        level_id = destination.level_id,
        x = destination.x,
        y = destination.y,
        dx = destination.x - origin.x,
        dy = destination.y - origin.y,
        entity = foe,
    }
end

-- An empty lava-struck floor may flood temporarily. Air strikes may leave
-- a storm cloud, but never overwrite an existing cloud at that cell.
local function after_cell(ctx, caster, spell_id, cell, flavour)
    if flavour == flavours.BEAM_LAVA then
        if ctx:cell(cell.level_id, cell.x, cell.y) ==
            terrain.DNGN_FLOOR and
            not ctx:actor_at(cell.level_id, cell.x, cell.y) and
            ctx:random(streams.MONSTER_SPELL, 2) == 0 then
            local duration = ctx:random(streams.MONSTER_SPELL, 14) * 10

            temporary.place(ctx, caster, spell_id,
                cell.level_id, cell.x, cell.y,
                terrain.DNGN_LAVA, duration)
        end

        return
    end

    if flavour == flavours.BEAM_AIR and
        not placement.at(ctx, cell.level_id, cell.x, cell.y) and
        ctx:random(streams.MONSTER_SPELL, 2) == 0 then
        local duration = ctx:random(streams.MONSTER_SPELL, 7) * 10

        placement.place(ctx, clouds.CLOUD_STORM, caster,
            cell.level_id, cell.x, cell.y, duration)
    end
end

-- Resolve the saved cell, choose one source flavour for the whole cast,
-- then strike its cells in shuffled order with independent three-die hits.
function upheaval.resolve(ctx, caster, plan, randomize, spell_id)
    local origin = ctx:get(caster, component.POSITION)

    if not origin or not plan or plan.kind ~= target_kind.CELL or
        plan.level_id ~= origin.level_id or
        plan.dx ~= plan.x - origin.x or
        plan.dy ~= plan.y - origin.y then
        error("Upheaval target plan differs from the selected cell")
    end

    local variant = randomize and
        ctx:random(streams.MONSTER_SPELL, #variants) + 1 or 1
    local flavour = variants[variant]
    local profile = {
        flavour = flavour,
    }
    local cells = affected_cells(ctx,
        plan.level_id, plan.x, plan.y)

    shuffle(ctx, cells)

    for _, cell in ipairs(cells) do
        local victim = ctx:actor_at(cell.level_id, cell.x, cell.y)

        if victim then
            local health = ctx:get(victim, component.HEALTH)

            if health and health.current > 0 then
                local raw = DICE

                for _ = 1, DICE do
                    raw = raw + roll.spell(ctx, SIDES)
                end

                impact.hit(ctx, caster, victim, raw, profile)
            end
        end

        after_cell(ctx, caster, spell_id, cell, flavour)
    end

    if senses.player_sees_cell(ctx, {
        level_id = plan.level_id,
        x = plan.x,
        y = plan.y,
    }) and not targets.allied(ctx, caster) then
        ctx:emit(channels.SPELL, messages[variant])
    end
end

return upheaval
