-- Sacrifice Experience changes the level cost immediately. The ordinary
-- character owner compares saved XP with the newly shifted thresholds and
-- recalculates HP and MP; Ru does not implement a second levelling rule.
local advancement = require("policy.character.advancement")

local experience = {}

-- Source calls level_change after granting Inexperienced. At ordinary XL
-- this commonly loses one level; at the cap it also enforces the new cap.
function experience.apply(ctx, player)
    advancement.reconcile_loss(ctx, player)
end

return experience
