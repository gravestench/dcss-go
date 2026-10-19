local boons = require("policy.combat.monster_support.boons")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local self_target = require("policy.combat.monster_support.self_target")
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")

local haste = {}

-- Source beam.cc excludes stationary and stasis monsters from Haste.
local function can_speed_up(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STATIONARY or flag == flags.STASIS then
            return false
        end
    end

    return true
end

-- Plan only an absent, useful Haste so a rejected cast spends no action.
function haste.plan(ctx, caster, foe)
    if boons.hasted(ctx, caster) or
        not self_target.useful(ctx, caster, foe) or
        not can_speed_up(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Store the speed boon; monster energy reads this same state on later turns.
function haste.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    boons.haste(ctx, caster, duration.beneficial(ctx, caster))
    ctx:emit("spell", "The " .. display.name(ctx, caster) ..
        " seems to speed up.")
end

return haste
