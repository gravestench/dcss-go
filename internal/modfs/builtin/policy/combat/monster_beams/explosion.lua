local contact = require("policy.combat.monster_beams.contact")
local explosion = require("policy.combat.explosion")
local explosion_sizes = require("constants.beam_explosion")

local blast = {}

function blast.resolve(ctx, caster, profile, trace,
    destination, power, to_hit, hook)
    local center_x = destination.x
    local center_y = destination.y

    if trace.contacts[1] then
        center_x = trace.contacts[1].x
        center_y = trace.contacts[1].y
    elseif trace.blocked then
        center_x = trace.x
        center_y = trace.y
    end

    local cells = explosion.cells(ctx, destination.level_id,
        center_x, center_y, explosion_sizes.DEFAULT_RADIUS)
    local outcomes = {}

    for _, cell in ipairs(cells) do
        local defender = ctx:actor_at(destination.level_id,
            cell.x, cell.y)

        if defender then
            outcomes[#outcomes + 1] = contact.resolve(ctx, caster,
                defender, profile, power, to_hit, hook)
        end
    end

    return outcomes
end

return blast
