local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local embers = {}

function embers.apply()
    -- Embers smoulder until their expiry; only the resulting fire burns.
end

function embers.expire(ctx, entity, state)
    local occupant = ctx:actor_at(state.level_id, state.x, state.y)

    if occupant then
        local actor = ctx:get(occupant, component.ACTOR)

        if not actor or occupant == ctx:player() then
            ctx:emit("spell", "You smother the flame.")
            ctx:destroy(entity)
            return
        end

        local definition = require("policy.catalog").get("monsters", actor.kind_id)
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
    state.kind_id = zap_ids.cloud.FIRE
    state.expires_aut = ctx:aut() + pending.fire_duration_aut
    ctx:set(entity, component.CLOUD, state)
    ctx:emit("spell", "The fire ignites!")
end

return embers
