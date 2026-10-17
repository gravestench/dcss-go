local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local explosion = require("policy.combat.explosion")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local mephitic_cloud = {}

function mephitic_cloud.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local impact = ray.contacts[1]
    local center_x = impact and impact.x or ray.x
    local center_y = impact and impact.y or ray.y
    local capped = math.min(power, 100)

    -- beam.cc:affect_place_explosion_clouds always clouds the center and
    -- rolls (125+power)/225 for every other radius-one blast cell.
    for _, cell in ipairs(explosion.cells(ctx, origin.level_id,
        center_x, center_y, 1)) do
        if cell.x == center_x and cell.y == center_y or
            ctx:random("spell", 225) < 125 + capped then
            local sides = 3 + math.floor(capped / 20)
            local duration = 2 + ctx:random("spell", sides) +
                ctx:random("spell", sides)

            cloud.place(ctx, cloud_ids.CLOUD_MEPHITIC, player,
                origin.level_id, cell.x, cell.y, duration * 10)
        end
    end

    ctx:emit("spell", "Noxious fumes billow out!")
end

registry.add(spells.SPELL_MEPHITIC_CLOUD, mephitic_cloud)

return mephitic_cloud
