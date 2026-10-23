-- Qazlal accepts all five ordinary kill classes. Storm and noise effects
-- are turn systems rather than extra rewards hidden in conduct.
local common = require("policy.religion.conduct.common")

local qazlal = {
    likes = common.kills(),
}

return qazlal
