-- Theory of operation: the source column and pillar maps share one rule:
-- glass becomes a crystal wall in Dis. Other branches retain transparent
-- glass and therefore keep their intended view through the barrier.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local setup = {}

-- Emit the Dis substitution at each map's authored hook position, before
-- placement so its MAP glyphs turn into the proper branch terrain.
local function dis_columns(api)
    if api:branch_id() == branches.BRANCH_DIS then
        api:emit(directives.SUBST, "m = b")
    end
end

setup.dis_columns = dis_columns

return setup
