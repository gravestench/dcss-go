local boons = require("policy.combat.monster_support.boons")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local self_target = require("policy.combat.monster_support.self_target")
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")

local might = {}

-- A stationary monster cannot profit from source BEAM_MIGHT.
local function can_grow_stronger(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STATIONARY then
            return false
        end
    end

    return true
end

-- A duplicate Might enchantment cannot earn another monster spell slot.
function might.plan(ctx, caster, foe)
    if boons.mighty(ctx, caster) or
        not self_target.useful(ctx, caster, foe) or
        not can_grow_stronger(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Both spells and Chaos read the same saved melee-damage timer.
function might.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    boons.might(ctx, caster, duration.beneficial(ctx, caster))
    ctx:emit("spell", "The " .. display.name(ctx, caster) ..
        " seems to grow stronger.")
end

return might
