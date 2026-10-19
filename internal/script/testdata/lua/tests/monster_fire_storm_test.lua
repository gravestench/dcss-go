-- Fire Storm's spell file owns the radius roll and cell effects, while the
-- production blast owner expands that saved radius across open terrain.
local beam = require("policy.combat.monster_beams")
local blast = require("policy.combat.monster_beams.explosion")
local clouds = require("ids.clouds")
local component = require("constants.component")
local effect = require("policy.combat.monster_spells.fire_storm")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local placement = require("policy.clouds.placement")
local summons = require("policy.magic.effects.summons.common")
local target_kind = require("constants.target_kind")
local targeting = require("policy.combat.monster_area.targeting")
local terrain = require("constants.terrain")

local test = {}
local caster = 11
local foe = 22

-- Host services expose one floor cell and one water cell to the source
-- after-cell rule. Changing the die choice tests both legal radii.
local function context()
    local state = {
        radius_roll = 0,
    }
    local ctx = {}

    -- Source power reads the live caster's monster identity and statuses.
    function ctx:get(entity, id)
        if entity == caster and id == component.ACTOR then
            return {
                kind_id = monsters.MONS_ANGEL,
            }
        end

        return nil
    end

    -- A zero radius roll makes the larger blast; other rolls remain zero.
    function ctx:random(_, bound)
        if bound == 1000 then
            return state.radius_roll
        end

        return 0
    end

    -- The second cell is water, so source flame must become steam there.
    function ctx:cell(_, x, y)
        if x == 3 and y == 3 then
            return terrain.DNGN_SHALLOW_WATER
        end

        if x >= 0 and x < 7 and y >= 0 and y < 7 then
            return terrain.DNGN_FLOOR
        end

        return nil
    end

    -- All present fixture cells let the real explosion owner propagate.
    function ctx:walkable(level_id, x, y)
        return self:cell(level_id, x, y) ~= nil
    end

    -- Both named test cells remain unoccupied for vortex eligibility.
    function ctx:actor_at()
        return nil
    end

    return ctx, state
end

-- Restore module methods because other Lua tests share the runtime cache.
local function restore(old)
    targeting.plan = old.plan
    beam.resolve = old.resolve
    placement.place = old.place
    summons.spawn = old.spawn
end

-- Verify the saved footprint, fire/steam placements, floor-only vortex,
-- and production explosion expansion beyond the old radius-one default.
function test.run()
    local old = {
        plan = targeting.plan,
        resolve = beam.resolve,
        place = placement.place,
        spawn = summons.spawn,
    }
    local ctx, state = context()
    local planned_radius
    local resolved_radius
    local placed = {}
    local summoned = {}

    -- Keep target selection fixed so this test isolates Fire Storm's roll.
    targeting.plan = function(_, _, _, profile)
        planned_radius = profile.explosion_radius

        return {
            kind = target_kind.CELL,
            level_id = 1,
            x = 3,
            y = 2,
            dx = 1,
            dy = 0,
        }
    end

    -- Invoke the real spell's cell callback at two different terrain cells.
    beam.resolve = function(_, _, _, profile, _, hook)
        resolved_radius = profile.explosion_radius
        hook.after_cell(ctx, caster, profile, {
            level_id = 1,
            x = 3,
            y = 2,
        })
        hook.after_cell(ctx, caster, profile, {
            level_id = 1,
            x = 3,
            y = 3,
        })
    end

    -- Record cloud kinds and durations chosen by the production callback.
    placement.place = function(_, kind, _, _, x, y, duration)
        placed[#placed + 1] = {
            kind = kind,
            x = x,
            y = y,
            duration = duration,
        }
    end

    -- Preserve the exact destination and source creature identity.
    summons.spawn = function(_, _, _, kind, _, _, options)
        summoned[#summoned + 1] = {
            kind = kind,
            x = options.exact.x,
            y = options.exact.y,
        }
    end

    local plan = effect.plan(ctx, caster, foe)

    harness.equal(planned_radius, 3,
        "a favorable source roll plans radius three")
    harness.equal(plan.radius, 3,
        "the radius survives in the selected target plan")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.equal(resolved_radius, 3,
        "resolution uses the saved radius without rerolling")
    harness.equal(placed[1].kind, clouds.CLOUD_FIRE,
        "an open floor cell receives a fire cloud")
    harness.equal(placed[2].kind, clouds.CLOUD_STEAM,
        "fire contacting water creates steam")
    harness.equal(#summoned, 1,
        "only ordinary empty floor may release a fire vortex")
    harness.equal(summoned[1].kind, monsters.MONS_FIRE_VORTEX,
        "the summoned actor uses the shared monster identity")

    state.radius_roll = 999

    local small = effect.plan(ctx, caster, foe)

    harness.equal(small.radius, 2,
        "an unfavorable source roll plans radius two")

    local cells = 0

    -- The production blast owner must visit every reached cell even when
    -- no actor occupies it; otherwise clouds would appear only on victims.
    blast.resolve(ctx, caster, {
        explosion_radius = 2,
    }, {
        contacts = {},
    }, {
        level_id = 1,
        x = 3,
        y = 2,
    }, 0, 0, {
        after_cell = function()
            cells = cells + 1
        end,
    })
    harness.truthy(cells > 9,
        "a radius-two blast reaches beyond the old radius-one footprint")

    restore(old)
end

return test
