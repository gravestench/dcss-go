-- Pikel's bound lemures are removed as a delayed source action when he
-- dies or is banished. All generated levels retain ECS actors, so one
-- pass can reach marked minions without a cross-level work queue.
local cloud_ids = require("ids.clouds")
local clouds = require("policy.clouds.placement")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local pikel = {}

-- Original-class identity survives polymorph of Pikel's current body.
local function was_pikel(ctx, actor, definition)
    if definition.id == monsters.MONS_PIKEL then
        return true
    end

    local form = ctx:get(actor, component.MONSTER_POLYMORPH)

    return form and form.original_kind_id == monsters.MONS_PIKEL
end

-- The origin marker, not species alone, identifies Pikel's band. An
-- unrelated lemure remains in the world when the leader disappears.
function pikel.depart(ctx, actor, definition)
    if not was_pikel(ctx, actor, definition) then
        return false
    end

    local dismissed = 0

    for _, minion in ipairs(ctx:query({ component.PIKEL_BAND })) do
        local marker = ctx:get(minion, component.PIKEL_BAND)
        local position = ctx:get(minion, component.POSITION)

        if marker.band_member and position then
            ctx:remove_actor(minion, position.level_id)
            clouds.place(ctx, cloud_ids.CLOUD_BLACK_SMOKE, nil,
                position.level_id, position.x, position.y,
                30 + 10 * ctx:random(streams.CLOUDS, 3))
            ctx:destroy(minion)
            dismissed = dismissed + 1
        end
    end

    if dismissed > 0 then
        ctx:emit("combat", "Pikel's former minions vanish in smoke.")
    end

    return false
end

death_hooks.add("pikel.band", pikel.depart)

return pikel
