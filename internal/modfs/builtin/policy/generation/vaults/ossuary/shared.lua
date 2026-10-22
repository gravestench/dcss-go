-- Theory of operation: every destination preserves its own source MAP;
-- this common hook only gives each authored < cell an Ossuary return exit.
local directives = require("constants.vault_directives")

local shared = {}

-- Run after a map's source substitutions so all surviving < cells use the
-- same reciprocal return rule rather than ordinary upstairs travel.
local function setup(api)
    api:emit(directives.KFEAT, "< = exit_ossuary")
end

shared.setup = setup

return shared
