local component = require("constants.component")
local digging = require("policy.world.digging")
local spells = require("ids.spells")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")

local dig = {}

function dig.resolve(ctx, player, intent, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)
    local aim_x = origin.x + intent.dx
    local aim_y = origin.y + intent.dy
    local changed = digging.ray(ctx, origin.level_id,
        origin.x, origin.y, aim_x, aim_y, reach)

    if changed > 0 then
        ctx:emit("spell", "The rock shatters into small pieces.")
    end
end

registry.add(spells.SPELL_DIG, dig)

return dig
