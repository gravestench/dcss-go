-- Ink Cloud is a self-centered water escape. No projectile or beam profile
-- exists: the caster must stand in water and spreads ink through the pond.
-- Source: mon-cast.cc:SPELL_INK_CLOUD.
local area = require("policy.clouds.area")
local component = require("constants.component")
local clouds = require("ids.clouds")
local channels = require("constants.message_channels")
local streams = require("constants.rng_streams")
local self_target = require("policy.combat.monster_support.self_target")
local terrain = require("constants.terrain")
local senses = require("policy.character.senses")

local ink_cloud = {}

local FIELD_POWER = 30
local FIELD_CELLS = 30

-- The source refuses to squirt ink from dry ground. Keep that eligibility
-- check in the plan so AI can choose another action without spending time.
local function water_position(ctx, caster)
    local position = ctx:get(caster, component.POSITION)

    if not position then
        return nil
    end

    local feature = ctx:cell(position.level_id,
        position.x, position.y)

    if feature ~= terrain.DNGN_SHALLOW_WATER and
        feature ~= terrain.DNGN_DEEP_WATER then
        return nil
    end

    return position
end

-- Save only the caster identity; the water check is repeated at resolution
-- because movement can invalidate a prepared escape cast.
function ink_cloud.plan(ctx, caster)
    if not water_position(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Place the source thirty-cell ink field through the world-cloud owner.
-- Its terrain rule keeps every persisted ink entity on shallow/deep water.
function ink_cloud.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local position = water_position(ctx, caster)

    if not position then
        return nil
    end

    area.place(ctx, clouds.CLOUD_INK, caster,
        position.level_id, position.x, position.y,
        FIELD_POWER, FIELD_CELLS, streams.MONSTER_SPELL)

    -- The saved cloud exists even when its source water is outside sight.
    if senses.player_sees_cell(ctx, position) then
        ctx:emit(channels.SPELL,
            "A massive cloud of ink spreads through the water!")
    end
end

return ink_cloud
