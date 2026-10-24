local contact = require("policy.combat.monster_beams.contact")
local component = require("constants.component")
local explosion = require("policy.combat.explosion")
local explosion_sizes = require("constants.beam_explosion")
local plant_protection = require(
    "policy.religion.fedhas.protection")

local blast = {}

-- Example: with actor at blast endpoint,
-- blast.resolve(ctx, caster, profile, trace, destination, power, to_hit, hook) -> contact outcome for that actor
-- Expand the beam endpoint into blast cells; each occupant is resolved against the same profile.
function blast.resolve(ctx, caster, profile, trace,
    destination, power, to_hit, hook)
    local center_x = destination.x
    local center_y = destination.y

    local first = plant_protection.first_unprotected_contact(ctx,
        caster, trace.contacts)

    if first then
        center_x = first.x
        center_y = first.y
    elseif trace.blocked then
        center_x = trace.x
        center_y = trace.y
    end

    local cells = explosion.cells(ctx, destination.level_id,
        center_x, center_y,
        profile.explosion_radius or explosion_sizes.DEFAULT_RADIUS)
    local outcomes = {}

    for _, cell in ipairs(cells) do
        local defender = ctx:actor_at(destination.level_id,
            cell.x, cell.y)

        local health = defender and ctx:get(defender, component.HEALTH)

        -- A consumed Seracfall simulacrum still has an ECS record until
        -- the death phase, but it is no longer a blast recipient.
        if health and health.current > 0 then
            outcomes[#outcomes + 1] = contact.resolve(ctx, caster,
                defender, profile, power, to_hit, hook)
        end

        -- Fire Storm and other source blasts may affect the cell itself
        -- after contact, even when no actor stood there to be damaged.
        if hook and hook.after_cell then
            hook.after_cell(ctx, caster, profile, {
                level_id = destination.level_id,
                x = cell.x,
                y = cell.y,
            })
        end
    end

    return outcomes
end

return blast
