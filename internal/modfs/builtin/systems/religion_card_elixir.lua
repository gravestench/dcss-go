-- Theory of operation: an active Elixir heals the player after ordinary
-- regeneration on every action. It uses the action's elapsed aut and the
-- current maximum resources, then removes its saved timer when it ends.
local component = require("constants.component")

local system = {}

-- Source heals for the full action delay if Elixir was active when the
-- action began, even when that delay exhausts its remaining duration.
function system.update(ctx, player, aut)
    if player ~= ctx:player() then
        return
    end

    local status = ctx:get(player, component.RELIGION_CARD_ELIXIR)

    if not status or status.remaining_aut <= 0 then
        return
    end

    local health = ctx:get(player, component.HEALTH)
    local magic = ctx:get(player, component.MAGIC)
    local spell_status = ctx:get(player, "magic.player_status")
    local death_door = spell_status and spell_status.death_door_aut > 0

    if health and not death_door then
        local restored = math.floor(aut * health.max / 100)

        health.current = math.min(health.max, health.current + restored)
        ctx:set(player, component.HEALTH, health)
    end

    if magic then
        local restored = math.floor(aut * magic.max / 100)

        magic.current = math.min(magic.max, magic.current + restored)
        ctx:set(player, component.MAGIC, magic)
    end

    status.remaining_aut = math.max(0, status.remaining_aut - aut)

    if status.remaining_aut == 0 then
        ctx:remove(player, component.RELIGION_CARD_ELIXIR)
    else
        ctx:set(player, component.RELIGION_CARD_ELIXIR, status)
    end
end

register.system({
    id = "religion.card_elixir",
    scope = "active",
    query = { component.PLAYER },
    after = { "status.regeneration" },
    update = system.update,
})

return system
