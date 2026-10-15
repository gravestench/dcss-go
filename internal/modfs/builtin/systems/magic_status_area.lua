local component = require("constants.component")
local radiance = require("policy.magic.effects.statuses.toxic_radiance")
local system = {}

function system.update(ctx, actor, aut)
    if actor ~= ctx:player() then
        return
    end

    radiance.tick(ctx, actor, aut)
    local value = ctx:get(actor, component.AREA_STATUS)

    if not value then
        return
    end

    local corpse_before = value.corpse_rot_aut
    local toxic_before = value.toxic_radiance_aut
    local bog_before = value.noxious_bog_aut

    value.corpse_rot_aut = math.max(0, value.corpse_rot_aut - aut)
    value.toxic_radiance_aut = math.max(0,
        value.toxic_radiance_aut - aut)
    value.noxious_bog_aut = math.max(0, value.noxious_bog_aut - aut)

    if corpse_before > 0 and value.corpse_rot_aut == 0 then
        value.corpse_rot_power = 0
        ctx:emit("duration", "Your miasmic aura fades.")
    end

    if toxic_before > 0 and value.toxic_radiance_aut == 0 then
        value.toxic_radiance_power = 0
        ctx:emit("duration", "Your toxic aura wanes.")
    end

    if bog_before > 0 and value.noxious_bog_aut == 0 then
        ctx:emit("duration", "Your noxious spew wanes.")
    end

    if value.corpse_rot_aut == 0 and value.toxic_radiance_aut == 0 and
        value.noxious_bog_aut == 0 then
        ctx:remove(actor, component.AREA_STATUS)
    else
        ctx:set(actor, component.AREA_STATUS, value)
    end
end

-- Source: player-reacts.cc ticks the toxic aura before durations decay.
register.system({
    id = "magic.area_status.tick",
    scope = "active",
    query = {},
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
