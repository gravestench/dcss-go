-- Vehumet's source conduct uses the ordinary kill curve across holinesses.
-- Spell gifts and MP-on-kill effects use their own focused owners.
local common = require("policy.religion.conduct.common")

local vehumet = {
    likes = common.kills(),
}

return vehumet
