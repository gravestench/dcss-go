-- Lee's Rapid Deconstruction plans a material cell with the production
-- material and explosion owner; the test substitutes only host world data.
local component = require("constants.component")
local effect = require("policy.combat.monster_spells.lrd")
local harness = require("tests.harness")
local impact = require("policy.combat.monster_area.impact")
local monsters = require("ids.monsters")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local test = {}
local caster = 11
local foe = 22
local ally = 33

-- Put a rock wall beside a foe. Its center is solid and cannot be hit,
-- while the explosion must reach the living occupant to the south.
local function context()
    local actors = {
        [caster] = {
            level_id = 1,
            x = 0,
            y = 1,
        },
        [foe] = {
            level_id = 1,
            x = 2,
            y = 2,
        },
        [ally] = {
            level_id = 1,
            x = 1,
            y = 2,
        },
    }
    local ctx = {}
    local events = {}

    -- The monster definition supplies spell HD for the source's 6x power.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return actors[entity]
        end

        if id == component.ACTOR then
            return {
                kind_id = monsters.MONS_RAT,
            }
        end

        if id == component.HEALTH then
            return {
                current = 50,
            }
        end

        return nil
    end

    -- An absent player keeps this scene focused on monster collateral.
    function ctx:player()
        return nil
    end

    -- No fixture actor carries the player marker or optional statuses.
    function ctx:has()
        return false
    end

    -- The visible wall is a valid source candidate; ordinary floor is not.
    function ctx:cell(_, x, y)
        if x < 0 or x > 4 or y < 0 or y > 4 then
            return nil
        end

        if x == 2 and y == 1 then
            return terrain.DNGN_ROCK_WALL
        end

        return terrain.DNGN_FLOOR
    end

    -- The wall can radiate fragments but cannot hold an actor.
    function ctx:walkable(level_id, x, y)
        local feature = self:cell(level_id, x, y)

        return feature ~= nil and feature ~= terrain.DNGN_ROCK_WALL
    end

    -- The wall remains visible; target rejection must come from material
    -- and ally weighting instead of a visibility shortcut.
    function ctx:visible()
        return true
    end

    -- Offer one material wall and one ordinary floor candidate.
    function ctx:visible_cells()
        return {
            {
                x = 2,
                y = 1,
            },
            {
                x = 2,
                y = 2,
            },
        }
    end

    -- Live occupancy supplies direct targets and recipients of fragments.
    function ctx:actor_at(_, x, y)
        for entity, position in pairs(actors) do
            if position.x == x and position.y == y then
                return entity
            end
        end

        return nil
    end

    -- Minimum die rolls make source dice and AC behavior predictable.
    function ctx:random(_, bound)
        harness.truthy(bound > 0, "LRD rolls a positive die")

        return 0
    end

    -- Presentation is observed separately from the chosen damage cells.
    function ctx:emit(channel, message)
        events[#events + 1] = {
            channel = channel,
            message = message,
        }
    end

    return ctx, actors, events
end

-- Validate a wall-centered cast, its actual blast contact, and refusal
-- when equal-weight friendly collateral makes the source tracer unsafe.
function test.run()
    local old_enemy = targets.enemy
    local old_hit = impact.hit
    local ctx, actors, events = context()
    local hits = {}

    -- Mark only the foe hostile so the real decision owner weighs the ally.
    targets.enemy = function(_, _, entity)
        return entity == foe
    end

    -- Record the blast's selected victim and dice without replacing its
    -- target geometry or material selection.
    impact.hit = function(_, _, entity, raw, profile)
        hits[#hits + 1] = {
            entity = entity,
            raw = raw,
            flavour = profile.flavour,
        }
    end

    -- Move the ally away for the accepted cast.
    actors[ally].x = 4
    actors[ally].y = 4

    local plan = effect.plan(ctx, caster, foe)

    harness.truthy(plan, "fragmentable wall beside a foe is worth casting")
    harness.equal(plan.kind, target_kind.CELL,
        "the wall cell is saved across the monster intent")
    harness.equal(plan.x, 2, "the source wall is selected")
    harness.equal(plan.y, 1, "the source wall is selected")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.equal(#hits, 1, "only the foe is in the solid-center blast")
    harness.equal(hits[1].entity, foe,
        "fragmentation reaches the adjacent foe")
    harness.equal(hits[1].raw, 3,
        "minimum source rock roll is three damage")
    harness.equal(#events, 1,
        "the resolved blast emits one player-facing event")

    actors[ally].x = 1
    actors[ally].y = 2

    local refused = effect.plan(ctx, caster, foe)

    harness.falsy(refused,
        "equal-weight friendly collateral fails the source foe ratio")

    targets.enemy = old_enemy
    impact.hit = old_hit
end

return test
