local catalog = require("policy.catalog")
local bounce = require("policy.combat.beam_bounce")
local cloud_area = require("policy.clouds.area")
local cloud_sizes = require("constants.cloud_sizes")
local component = require("constants.component")
local explosion = require("policy.combat.explosion")
local explosion_sizes = require("constants.beam_explosion")
local power = require("policy.combat.monster_beams.power")
local spell_flags = require("constants.spell_flags")
local targets = require("policy.ai.targets")
local target_kind = require("constants.target_kind")
local trajectory = require("policy.combat.trajectory")

local targeting = {}

-- Read cloud and other spell flags while planning the monster beam's aim.
local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Example: targeting.plan(ctx, caster, foe, profile, options) with foe on another level -> nil plan
-- Target plans are built from the beam profile before the monster commits to its cast.
function targeting.plan(ctx, caster, foe, profile, options)
    local source = ctx:get(caster, component.POSITION)
    local destination = ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id then
        return nil
    end

    local reach = power.spell_range(ctx, caster, profile)
    local spell = catalog.get("spells", profile.id)
    local is_cloud = has_flag(spell.flags, spell_flags.CLOUD)
    local area_target = profile.is_explosion or is_cloud
    local distance = math.max(math.abs(destination.x - source.x),
        math.abs(destination.y - source.y))

    if reach < 0 or distance > reach then
        return nil
    end

    local trace

    -- Clouds and explosions aim at a cell; ordinary beams may trace through
    -- actors or bounce, according to their catalog profile.
    local can_bounce = bounce.for_profile(profile, options)

    if can_bounce and not area_target then
        trace = trajectory.bouncing(ctx, source.level_id,
            source.x, source.y, destination.x, destination.y,
            reach, can_bounce)
    elseif not area_target then
        trace = trajectory.trace(ctx, source.level_id,
            source.x, source.y, destination.x, destination.y, reach)
    else
        trace = trajectory.to_target(ctx, source.level_id,
            source.x, source.y, destination.x, destination.y, reach)
    end

    local reached = false
    local cloud_centers = {}

    for _, contact in ipairs(trace.contacts) do
        if not targets.enemy(ctx, caster, contact.actor) then
            return nil
        end

        if is_cloud then
            cloud_centers[#cloud_centers + 1] = contact
        end

        if contact.actor == foe then
            reached = true
        end

        if reached and area_target then
            break
        end

        if not reached and not profile.can_beam then
            return nil
        end
    end

    if not reached then
        return nil
    end

    -- A cloud ray can stop at any actor it hits. Protect allies around all
    -- possible contact centers, not only around the intended distant foe.
    if is_cloud then
        local max_size = options and options.cloud_max_size or
            cloud_sizes.MAX_VARIABLE

        for _, center in ipairs(cloud_centers) do
            local possible = cloud_area.candidates(ctx, source.level_id,
                center.x, center.y, max_size)

            for _, cell in ipairs(possible) do
                local actor = ctx:actor_at(source.level_id,
                    cell.x, cell.y)

                if actor and not targets.enemy(ctx, caster, actor) then
                    return nil
                end
            end
        end
    end

    if profile.is_explosion then
        local cells = explosion.cells(ctx, source.level_id,
            destination.x, destination.y,
            explosion_sizes.DEFAULT_RADIUS)

        for _, cell in ipairs(cells) do
            local actor = ctx:actor_at(source.level_id, cell.x, cell.y)

            if actor and not targets.enemy(ctx, caster, actor) then
                return nil
            end
        end
    end

    if area_target then
        return {
            kind = target_kind.CELL,
            level_id = source.level_id,
            x = destination.x,
            y = destination.y,
            dx = destination.x - source.x,
            dy = destination.y - source.y,
        }
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
        dx = destination.x - source.x,
        dy = destination.y - source.y,
    }
end

return targeting
