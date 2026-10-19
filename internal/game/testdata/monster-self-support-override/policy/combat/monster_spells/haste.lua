-- A mod can replace just one effect module under the same relative path.
-- This fixture emits a distinct result so the game test detects that layer.
local self_target = require("policy.combat.monster_support.self_target")

local haste = {}

-- Use the production self-target plan so only resolution differs.
function haste.plan(_, caster)
    return self_target.plan(caster)
end

-- The absence of a boon is intentional: a modded effect owns this spell.
function haste.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)
    ctx:emit("spell", "Modded Haste cast.")
end

return haste
