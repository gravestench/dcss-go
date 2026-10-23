-- Dithmenos uses the ordinary kill curve. Shadow passives depend on piety
-- rank but do not modify this event's award formula.
local common = require("policy.religion.conduct.common")

local dithmenos = {
    likes = common.kills(),
}

return dithmenos
