-- Illusion borrows the production player-ghost owner. That owner captures
-- combat values, carried body statuses, and spell choices once, so later
-- player changes cannot mutate the summoned copy or its saved state.
local cards = require("ids.cards")
local ghost = require("policy.combat.monster_summons.player_illusion")

local illusion = {}

illusion.uses_tier = true

-- Card strength changes lifetime, not the copy's current combat profile.
-- A blocked adjacent cell turns the attempted summon into source smoke.
function illusion.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Illusion requires a source power tier")
    end

    if ghost.spawn_card(ctx, player, cards.ILLUSION, tier) then
        ctx:emit("religion", "Suddenly you stand beside yourself.")
    else
        ctx:emit("religion", "You see a puff of smoke.")
    end
end

return illusion
