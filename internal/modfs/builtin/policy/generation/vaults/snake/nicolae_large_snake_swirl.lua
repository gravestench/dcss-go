-- Theory of operation: the source spiral changes its equipment glyphs at
-- the first and last Snake depths. The DES owns the shape; this hook only
-- chooses which glyph set its s placeholder can become.
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve source branch-depth comparisons, including the broad mixed
-- middle-floor choice when neither boundary case applies.
function handler.configure(api)
    local glyphs

    if api:depth() == 1 then
        glyphs = "]})"
    elseif api:depth() == api:branch_bottom() then
        glyphs = "[{("
    else
        glyphs = "]})[{("
    end

    api:emit(directives.SUBST, "s = " .. glyphs)
end

return handler
