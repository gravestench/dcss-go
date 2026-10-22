-- Okawaru will not accept a new worshipper's friendly magical army. The
-- joining player loses current-level summons before ordinary monster turns.
local attitudes = require("constants.attitude")
local channels = require("constants.message_channels")
local component = require("constants.component")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")

local okawaru = {}

-- Source _join_okawaru zeros friendly player summons' abjuration duration.
-- Expire them through the shared summon owner so carried items and spatial
-- occupancy are cleaned up as they are for a natural timeout.
function okawaru.join(ctx, player)
    local player_position = ctx:get(player, component.POSITION)

    if not player_position then
        return
    end

    local dismissed = {}

    for _, entity in ipairs(ctx:query({
        component.SUMMON,
        component.POSITION,
    })) do
        local state = ctx:get(entity, component.SUMMON)
        local position = ctx:get(entity, component.POSITION)

        if state.owner == player and
            targets.attitude(ctx, entity) == attitudes.FRIENDLY and
            position.level_id == player_position.level_id then
            dismissed[#dismissed + 1] = entity
        end
    end

    for _, entity in ipairs(dismissed) do
        summons.expire(ctx, entity)
    end

    if #dismissed > 0 then
        ctx:emit(channels.MONSTER, "Your summoned allies are dismissed!")
    end
end

return okawaru
