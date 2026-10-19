local categories = require("constants.catalog")
local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local cloud_ids = require("ids.clouds")
local attitudes = require("constants.vault_attitude")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local embers = {}

-- Embers have no direct contact effect; expiry determines whether fire appears.
function embers.apply()
    -- Embers smoulder until their expiry; only the resulting fire burns.
end

-- Friendly or authored allies avoid an ember that may turn into fire.
function embers.avoid(ctx, monster)
    local summon = ctx:get(monster, component.SUMMON)

    if summon and not summon.hostile then
        return true
    end

    local authored = ctx:get(monster,
        component.VAULT_ACTOR_OVERRIDES)

    if authored and authored.attitude == attitudes.FRIENDLY then
        return true
    end

    return allegiance.charmed(ctx, monster)
end

-- Resolve the saved ember only on expiry; occupants can smother it before it becomes fire.
-- Example: an occupied ember can be smothered; an empty ember becomes fire for its saved duration.
function embers.expire(ctx, entity, state)
    local occupant = ctx:actor_at(state.level_id, state.x, state.y)

    if occupant then
        local actor = ctx:get(occupant, component.ACTOR)

        if not actor or occupant == ctx:player() then
            ctx:emit("spell", "You smother the flame.")
            ctx:destroy(entity)
            return
        end

        local definition = require("policy.catalog").get(categories.MONSTERS, actor.kind_id)
        local conjured = false

        for _, flag in ipairs(definition.flags or {}) do
            if flag == "M_CONJURED" then
                conjured = true
                break
            end
        end

        if not conjured then
            ctx:emit("spell", "The " .. definition.name ..
                " smothers the flame.")
            ctx:destroy(entity)
            return
        end
    end

    local pending = ctx:get(entity, zap_ids.component.CONJURE_FLAME)

    if not pending then
        error("conjured embers lost their fire duration")
    end

    ctx:remove(entity, zap_ids.component.CONJURE_FLAME)
    state.kind_id = cloud_ids.CLOUD_FIRE
    state.decay_aut = pending.fire_duration_aut
    ctx:set(entity, component.WORLD_CLOUD, state)
    ctx:emit("spell", "The fire ignites!")

    return true
end

return embers
