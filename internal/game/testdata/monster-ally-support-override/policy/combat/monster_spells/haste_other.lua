local ally_target = require("policy.combat.monster_support.ally_target")
local channels = require("constants.message_channels")
local spells = require("ids.spells")

local haste_other = {}

-- The overlay keeps the real target decision to isolate effect replacement.
local function benefits()
    return true
end

-- The base book calls this named plan phase without a Go registry edit.
function haste_other.plan(ctx, caster)
    return ally_target.plan(ctx, caster, spells.SPELL_HASTE_OTHER, benefits)
end

-- A distinct event proves that this one overlaid module ran at resolution.
function haste_other.resolve(ctx, caster, _, _, plan)
    local target = ally_target.selected(ctx, caster, plan)

    if target then
        ctx:emit(channels.SPELL, "Modded ally Haste cast.")
    end
end

return haste_other
