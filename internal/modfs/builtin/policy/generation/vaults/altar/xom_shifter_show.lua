-- Theory of operation: the shifter-show map can place an escape stair on
-- ordinary floors. On the branch's bottom floor its source changes that
-- downward stair into an upward stair before general wall substitutions.
local directives = require("constants.vault_directives")

local handler = {}

-- The final-floor conversion prevents a stair from leaving the branch.
local function turn_bottom_stair(api)
    if api:depth() == api:branch_bottom() then
        api:emit(directives.SUBST, "> = <")
    end
end

handler.turn_bottom_stair = turn_bottom_stair

return handler
