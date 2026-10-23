-- Wu Jian's source conduct has the ordinary kill rewards. Martial movement
-- remains a separate ability domain and does not alter these five rules.
local common = require("policy.religion.conduct.common")

local wu_jian = {
    likes = common.kills(),
}

return wu_jian
