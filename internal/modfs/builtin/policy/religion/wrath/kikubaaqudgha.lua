-- Kikubaaqudgha's high-level punishment uses the saved Torment area owner.
-- Lesser punishments use the weighted death curse and its saved effect owners.
local area = require("policy.combat.torment_area")
local channels = require("constants.message_channels")
local component = require("constants.component")
local curse = require("policy.religion.wrath.death_curse")
local gods = require("constants.gods")
local resistance = require("policy.combat.player_resistance")
local streams = require("constants.rng_streams")

local kikubaaqudgha = {}

-- god-wrath.cc chooses the speech first, then the XL/27 Torment gate. A
-- resisted Torment substitutes three maximum-power death curses in source.
function kikubaaqudgha.apply(ctx, player)
    local level = math.max(1,
        ctx:get(player, component.PROGRESSION).level)

    ctx:emit(channels.RELIGION, ctx:random(streams.CARDS, 2) ~= 0 and
        "You hear Kikubaaqudgha cackling." or
        "Kikubaaqudgha's malice focuses upon you.")

    if ctx:random(streams.CARDS, 27) < level then
        if resistance.torment(ctx, player) then
            for _ = 1, 3 do
                curse.apply(ctx, player, level)
            end

            return true
        end

        -- Source passes no actor caster; the player's cell is only the
        -- Torment origin and must not credit the player as its attacker.
        area.apply(ctx, nil, channels.RELIGION,
            ctx:get(player, component.POSITION))
    elseif ctx:random(streams.CARDS, level) >= 4 then
        local count = ctx:random(streams.CARDS, 4) == 0 and 2 or 1

        for _ = 1, count do
            curse.apply(ctx, player, level)
        end
    end

    return true
end

return kikubaaqudgha
