-- Seracfall chooses a player-visible allied simulacrum, saves its handle,
-- and consumes it before the Iceblast is resolved from the donor's cell.
local blast = require("policy.combat.monster_beams.explosion")
local component = require("constants.component")
local effect = require("policy.combat.monster_spells.seracfall")
local harness = require("tests.harness")
local monster_health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local senses = require("policy.character.senses")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local test = {}
local caster = 11
local donor = 22
local foe = 33

-- A straight, open ray from the donor reaches the foe. The fixture keeps
-- actor state separate from the fixed monster definitions.
local function context()
    local positions = {
        [caster] = {
            level_id = 1,
            x = 0,
            y = 0,
        },
        [donor] = {
            level_id = 1,
            x = 1,
            y = 1,
        },
        [foe] = {
            level_id = 1,
            x = 3,
            y = 1,
        },
    }
    local health = {
        [caster] = 50,
        [donor] = 20,
        [foe] = 50,
    }
    local ctx = {}
    local events = {}

    -- The donor's kind is the source's exact simulacrum requirement.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.ACTOR then
            return {
                kind_id = entity == donor and
                    monsters.MONS_SIMULACRUM or monsters.MONS_RAT,
            }
        end

        if id == component.HEALTH then
            return {
                current = health[entity],
                max = 50,
            }
        end

        return nil
    end

    -- No optional status changes donor selection in this fixture.
    function ctx:has()
        return false
    end

    -- Offer caster, donor, and foe to the real candidate filter.
    function ctx:query()
        return { caster, donor, foe }
    end

    -- An open grid keeps the blast centered on its first actor contact.
    function ctx:cell(_, x, y)
        if x < 0 or x > 5 or y < 0 or y > 5 then
            return nil
        end

        return terrain.DNGN_FLOOR
    end

    -- Ray tracing stops only at the fixture's outer boundary.
    function ctx:walkable(level_id, x, y)
        return self:cell(level_id, x, y) ~= nil
    end

    -- Candidate rejection comes from allegiance and player visibility.
    function ctx:visible_no_trans()
        return true
    end

    -- The real ray owner sees the saved donor and foe positions.
    function ctx:actor_at(_, x, y)
        for entity, position in pairs(positions) do
            if position.x == x and position.y == y then
                return entity
            end
        end

        return nil
    end

    -- Keep cast messages separate from the ECS sacrifice assertion.
    function ctx:emit(kind, message)
        events[#events + 1] = {
            kind = kind,
            message = message,
        }
    end

    return ctx, positions, health, events
end

-- The plan is a cell plus a donor handle. No alternate donor may be
-- substituted during resolution, and a dead donor refuses the cast.
function test.run()
    local old = {
        aligned = targets.aligned,
        enemy = targets.enemy,
        visible = senses.player_sees_cell,
        damage = monster_health.damage,
        blast = blast.resolve,
    }
    local ctx, positions, health, events = context()
    local fired

    -- Only the simulacrum belongs to the caster's side.
    targets.aligned = function(_, _, actor)
        return actor == donor
    end

    -- The foe is the only body that improves the damage fraction.
    targets.enemy = function(_, _, actor)
        return actor == foe
    end

    -- Seracfall refuses hidden donors; the first pass exposes this one.
    senses.player_sees_cell = function()
        return true
    end

    -- Record the exact donor sacrifice before allowing the blast call.
    monster_health.damage = function(_, actor, amount)
        harness.equal(actor, donor,
            "the source consumes the planned simulacrum")
        health[actor] = health[actor] - amount
    end

    -- Capture the real spell's Iceblast origin and destination.
    blast.resolve = function(_, _, profile, trace, destination)
        fired = {
            profile = profile,
            trace = trace,
            destination = destination,
        }
    end

    local plan = effect.plan(ctx, caster, foe)

    harness.truthy(plan, "a safe visible donor can be planned")
    harness.equal(plan.kind, target_kind.CELL,
        "Seracfall saves the foe's cell")
    harness.equal(plan.entity, donor,
        "Seracfall saves the donor separately")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.equal(health[donor], 0,
        "the donor dies before the blast")
    harness.equal(fired.trace.x, positions[foe].x,
        "the ray starts at the donor and reaches the foe")
    harness.equal(fired.destination.x, positions[foe].x,
        "the original target cell is retained")
    harness.equal(fired.profile.explosion_radius, 1,
        "the source Iceblast uses a radius-one explosion")
    harness.equal(#events, 2,
        "the collapse and explosion are both announced")

    health[donor] = 20
    -- Removing player sight makes the same donor unusable.
    senses.player_sees_cell = function()
        return false
    end

    harness.falsy(effect.plan(ctx, caster, foe),
        "an unseen donor cannot be used for Seracfall")

    targets.aligned = old.aligned
    targets.enemy = old.enemy
    senses.player_sees_cell = old.visible
    monster_health.damage = old.damage
    blast.resolve = old.blast
end

return test
