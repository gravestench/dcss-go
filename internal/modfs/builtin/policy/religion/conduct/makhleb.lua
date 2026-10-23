-- Makhleb values kills of living, undead, demonic, holy, and nonliving foes.
-- The health-on-kill passive is a separate reaction to the same death.
local common = require("policy.religion.conduct.common")

local makhleb = {
    likes = common.kills(),
}

return makhleb
