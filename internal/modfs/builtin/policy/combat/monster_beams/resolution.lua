local blast = require("policy.combat.monster_beams.explosion")
local bounce = require("policy.combat.beam_bounce")
local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local component = require("constants.component")
local contact_rules = require("policy.combat.monster_beams.contact")
local beam_power = require("policy.combat.monster_beams.power")
local spell_flags = require("constants.spell_flags")
local target_kind = require("constants.target_kind")
local trajectory = require("policy.combat.trajectory")

local resolution = {}

-- A stopped cloud trail includes the contact cell but never the cells
-- beyond it, even though trajectory tracing found them before hit rolls.
local function path_through(path, x, y)
    local prefix = {}

    for _, cell in ipairs(path) do
        prefix[#prefix + 1] = cell

        if cell.x == x and cell.y == y then
            break
        end
    end

    return prefix
end

-- Only cloud and explosion spells may resolve a saved cell plan instead of an actor target.
local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Example: resolution.resolve(ctx, caster, foe, profile, plan, hook) with missing plan -> error before tracing
-- Validate the saved plan against the live caster and foe before tracing;
-- execution cannot silently retarget a different actor or direction.
function resolution.resolve(ctx, caster, foe, profile, plan, hook)
    if not plan then
        error("monster beam has no target plan")
    end

    local source = ctx:get(caster, component.POSITION)

    if not source then
        error("monster beam caster has no position")
    end

    local destination
    local area_target = plan.kind == target_kind.CELL
    local is_cloud = false

    if area_target then
        local spell = catalog.get("spells", profile.id)

        is_cloud = has_flag(spell.flags, spell_flags.CLOUD)

        if not profile.is_explosion and
            not is_cloud then
            error("non-area monster beam received a cell plan")
        end

        destination = {
            level_id = plan.level_id,
            x = plan.x,
            y = plan.y,
        }
    elseif plan.kind == target_kind.ENTITY and plan.entity == foe then
        destination = ctx:get(foe, component.POSITION)
    else
        error("monster beam target plan does not match the selected foe")
    end

    if not destination or
        source.level_id ~= destination.level_id then
        error("monster beam target moved off the caster's level")
    end

    if plan.dx ~= destination.x - source.x or
        plan.dy ~= destination.y - source.y then
        error("monster beam direction changed after planning")
    end

    local power = beam_power.caster_power(ctx, caster, profile)
    local reach = beam_power.spell_range(ctx, caster, profile)
    local to_hit = calculators.to_hit(profile, power)
    local outcomes = {}
    local leg_source = source
    local remaining = reach
    local trace

    -- Area plans stop at their selected cell, while bouncing beams need the
    -- ray path and remaining range for each reflected leg.
    local can_bounce = bounce.for_profile(profile, hook)

    if profile.direct_explosion then
        -- Source direct explosions are placed at the selected cell even
        -- when an actor or clear wall lies along the intervening ray.
        trace = {
            contacts = {},
            x = destination.x,
            y = destination.y,
            path = {},
        }
    elseif area_target then
        trace = trajectory.to_target(ctx, source.level_id,
            source.x, source.y, destination.x, destination.y, remaining)
    elseif can_bounce then
        trace = trajectory.bouncing(ctx, source.level_id,
            source.x, source.y, destination.x, destination.y,
            remaining, can_bounce)
    else
        trace = trajectory.trace(ctx, source.level_id,
            source.x, source.y, destination.x, destination.y, remaining)
    end

    local endpoint = {
        level_id = source.level_id,
        x = trace.x,
        y = trace.y,
        path = trace.path,
    }

    if profile.is_explosion then
        return blast.resolve(ctx, caster, profile, trace,
            destination, power, to_hit, hook)
    end

    while trace do
        local next_trace = nil
        local stopped = false

        -- A penetrating beam can continue after a hit; a blocked or reflected
        -- contact ends this leg before the endpoint hook is called.
        for _, contact in ipairs(trace.contacts) do
            local outcome = contact_rules.resolve(ctx, caster, contact.actor,
                profile, power, to_hit, hook, leg_source)
            outcomes[#outcomes + 1] = outcome

            if outcome.kind == "hit" then
                -- Source beam.cc stops a big-cloud ray on a landed actor
                -- even when its zap profile is marked as piercing.
                if not profile.can_beam or is_cloud then
                    endpoint.x = contact.x
                    endpoint.y = contact.y
                    endpoint.path = path_through(trace.path,
                        contact.x, contact.y)
                    stopped = true
                    break
                end
            elseif outcome.kind == "reflect" then
                contact_rules.register_block(ctx, contact.actor)
                local distance = math.max(
                    math.abs(contact.x - leg_source.x),
                    math.abs(contact.y - leg_source.y))
                remaining = remaining - distance

                if remaining > 0 then
                    -- beam.cc:bolt::reflect chooses a reverse ray, which
                    -- keeps travelling past the old source if range remains.
                    next_trace = trajectory.trace(ctx,
                        source.level_id, contact.x, contact.y,
                        leg_source.x, leg_source.y, remaining)
                    endpoint.x = next_trace.x
                    endpoint.y = next_trace.y
                    endpoint.path = next_trace.path
                    leg_source = {
                        level_id = source.level_id,
                        x = contact.x,
                        y = contact.y,
                    }
                else
                    endpoint.x = contact.x
                    endpoint.y = contact.y
                end

                stopped = true
                break
            elseif outcome.kind == "block" then
                contact_rules.register_block(ctx, contact.actor)
                endpoint.x = contact.x
                endpoint.y = contact.y
                endpoint.path = path_through(trace.path,
                    contact.x, contact.y)
                stopped = true
                break
            end
        end

        if stopped and not next_trace then
            break
        end

        trace = next_trace
    end

    if hook and hook.after_endpoint then
        hook.after_endpoint(ctx, caster, profile, plan, endpoint)
    end

    return outcomes
end

return resolution
