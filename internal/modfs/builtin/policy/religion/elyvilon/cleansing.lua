-- Purification removes source debuffs through their existing ECS owners.
-- Temporary stat and HP drain have separate resource consequences, so
-- cleansing them must update derived HP instead of only deleting records.
local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")
local zap = require("policy.magic.effects.zaps.ids").component

local cleansing = {}

local removable = {
    component.POISON,
    component.PLAYER_SLOW,
    component.PLAYER_PETRIFICATION,
    component.PLAYER_WEAKNESS,
    component.STAT_LOSS,
    component.PLAYER_DRAIN,
    zap.PLAYER_CONFUSION,
}

-- Menu preparation must reject a healthy player without advancing time.
-- The same list drives application so a new status cannot be advertised
-- as curable yet left behind by the successful ability.
function cleansing.needed(ctx, player)
    for _, id in ipairs(removable) do
        if ctx:has(player, id) then
            return true
        end
    end

    return false
end

-- Remove all represented source ailments. Losing HP drain changes the
-- derived maximum and proportionally rescales current HP as calc_hp does.
function cleansing.apply(ctx, player)
    local drained = ctx:has(player, component.PLAYER_DRAIN)

    for _, id in ipairs(removable) do
        if ctx:has(player, id) then
            ctx:remove(player, id)
        end
    end

    if drained then
        forms.rescale_health(ctx, player, forms.max_hp(ctx, player))
    end

    ctx:emit("religion", "You feel purified!")
end

return cleansing
