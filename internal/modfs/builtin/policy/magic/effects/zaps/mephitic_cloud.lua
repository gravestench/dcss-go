local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local burst = require("policy.clouds.mephitic_burst")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local mephitic_cloud = {}

-- Example: A successful Mephitic Cloud ray leaves a noxious cloud at its impact cell.
-- Trace the ray once, always cloud its impact center, and roll spread for the other radius-one cells.
function mephitic_cloud.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local impact = ray.contacts[1]
    local center_x = impact and impact.x or ray.x
    local center_y = impact and impact.y or ray.y
    burst.place(ctx, player, origin.level_id,
        center_x, center_y, power, "spell")

    ctx:emit("spell", "Noxious fumes billow out!")
end

registry.add(spells.SPELL_MEPHITIC_CLOUD, mephitic_cloud)

return mephitic_cloud
