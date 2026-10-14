-- Natural monster regeneration from mon-act.cc:125-160,1724 and
-- monster.cc:2934-2942. The active floor scheduler supplies action order.

local catalog = require("policy.catalog")

local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

register.system({
    id = "monster.regeneration",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = function(ctx, entity)
        if not ctx:has(entity, "core.ai") then
            return
        end

        local actor = ctx:get(entity, "core.actor")
        local health = ctx:get(entity, "core.health")

        if not actor then
            error("regenerating monster has no actor")
        end

        if not health or health.current < 0 or health.max <= 0 or
            health.current > health.max then
            error("regenerating monster has invalid health")
        end

        if health.current == 0 or health.current == health.max then
            return
        end

        local definition = catalog.get("monsters", actor.kind_id)

        if has_flag(definition.flags, "M_FAST_REGEN") then
            health.current = health.current + 1
        elseif definition.hd >= 1 and definition.hd <= 2 then
            if ctx:random("monster_regen", 25) == 0 then
                health.current = health.current + 1
            end
        else
            error("unsupported natural regeneration for " .. actor.kind_id)
        end

        ctx:set(entity, "core.health", health)
    end,
})
