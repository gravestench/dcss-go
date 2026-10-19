-- Upheaval and Eruption use the production area and spell entry points.
-- The fixture supplies only a small grid and records external damage,
-- cloud, terrain, and presentation services after the rule chooses cells.
local component = require("constants.component")
local eruption = require("policy.combat.monster_spells.eruption")
local flavours = require("constants.beam_flavours")
local harness = require("tests.harness")
local impact = require("policy.combat.monster_area.impact")
local monsters = require("ids.monsters")
local placement = require("policy.clouds.placement")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")
local temporary = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")
local upheaval = require("policy.combat.monster_spells.upheaval")

local test = {}
local caster = 11
local foe = 22

-- Keep the source target beside a solid wall; only its eight non-solid
-- neighbors and center may receive an individual blast.
local function context()
    local positions = {
        [caster] = {
            level_id = 1,
            x = 0,
            y = 0,
        },
        [foe] = {
            level_id = 1,
            x = 2,
            y = 2,
        },
    }
    local ctx = {}
    local draws = {}

    -- The decision reads actual monster definitions through these actor IDs.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.HEALTH then
            return { current = 50 }
        end

        if id == component.ACTOR then
            return { kind_id = monsters.MONS_RAT }
        end

        return nil
    end

    -- This fixture has no player; the caster and foe are monster handles.
    function ctx:has()
        return false
    end

    -- One adjacent wall is never struck, while the center is always kept.
    function ctx:cell(_, x, y)
        if x < 0 or x > 4 or y < 0 or y > 4 then
            return nil
        end

        if x == 1 and y == 2 then
            return terrain.DNGN_STONE_WALL
        end

        return terrain.DNGN_FLOOR
    end

    -- Source planning checks sight before scoring possible collateral.
    function ctx:visible()
        return true
    end

    -- Only the foe occupies the proposed strike cells.
    function ctx:actor_at(level_id, x, y)
        if positions[foe].level_id == level_id and
            positions[foe].x == x and positions[foe].y == y then
            return foe
        end

        return nil
    end

    -- Choose minimum damage and a nonzero duration. Upheaval selects air
    -- when the four-flavour variant draw is made.
    function ctx:random(_, bound)
        draws[#draws + 1] = bound

        if bound == 4 then
            return 2
        end

        if bound == 14 or bound == 7 then
            return 1
        end

        return 0
    end

    return ctx, positions, draws
end

-- Exercise the real plan/resolve methods, while observing their effects
-- at the existing health, cloud, and temporary-terrain owner boundaries.
function test.run()
    local old = {
        enemy = targets.enemy,
        allied = targets.allied,
        sees = senses.player_sees_cell,
        hit = impact.hit,
        cloud_at = placement.at,
        cloud_place = placement.place,
        terrain_place = temporary.place,
    }
    local hits = {}
    local clouds = {}
    local terrain_changes = {}

    targets.enemy = function(_, _, victim)
        return victim == foe
    end

    targets.allied = function()
        return false
    end

    senses.player_sees_cell = function()
        return false
    end

    impact.hit = function(_, _, victim, raw, profile)
        hits[#hits + 1] = {
            victim = victim,
            raw = raw,
            flavour = profile.flavour,
        }
    end

    placement.at = function()
        return nil
    end

    placement.place = function(_, kind_id, _, level_id, x, y, duration)
        clouds[#clouds + 1] = {
            kind_id = kind_id,
            level_id = level_id,
            x = x,
            y = y,
            duration = duration,
        }
    end

    temporary.place = function(_, _, spell_id, level_id, x, y, _, duration)
        terrain_changes[#terrain_changes + 1] = {
            spell_id = spell_id,
            level_id = level_id,
            x = x,
            y = y,
            duration = duration,
        }
    end

    local ctx, positions = context()
    local eruption_plan = eruption.plan(ctx, caster, foe)

    harness.truthy(eruption_plan,
        "a clear target with no allied bodies can be planned")
    eruption.resolve(ctx, caster, foe, nil, eruption_plan)
    harness.equal(#hits, 1,
        "only the living foe receives a magma hit")
    harness.equal(hits[1].raw, 3,
        "minimum source three-die roll deals three raw damage")
    harness.equal(hits[1].flavour, flavours.BEAM_LAVA,
        "Eruption always uses magma")
    harness.equal(#terrain_changes, 7,
        "empty floor cells can flood but a wall and occupied center cannot")

    hits = {}

    local upheaval_plan = upheaval.plan(ctx, caster, foe)

    upheaval.resolve(ctx, caster, foe, nil, upheaval_plan)
    harness.equal(hits[1].flavour, flavours.BEAM_AIR,
        "Upheaval chooses one source flavour for all cells")
    harness.equal(#clouds, 8,
        "every non-solid cell may leave a storm cloud")

    positions[foe].level_id = 2
    hits = {}

    eruption.resolve(ctx, caster, foe, nil, eruption_plan)
    harness.equal(#hits, 0,
        "a saved cell plan strikes its original cell, not the moving foe")

    targets.enemy = old.enemy
    targets.allied = old.allied
    senses.player_sees_cell = old.sees
    impact.hit = old.hit
    placement.at = old.cloud_at
    placement.place = old.cloud_place
    temporary.place = old.terrain_place
end

return test
