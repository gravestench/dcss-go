-- Sif Muna's pinned source matrix includes ordinary kill appreciation.
-- It is easy to assume this god only values magic, so keep the source rule
-- explicit and let later magic-specific behavior live in its own module.
local common = require("policy.religion.conduct.common")

local sif_muna = {
    likes = common.kills(),
}

return sif_muna
