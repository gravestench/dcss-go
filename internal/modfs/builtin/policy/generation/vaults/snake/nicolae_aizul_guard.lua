-- Theory of operation: Aizul's guard post changes escorts beyond source
-- absolute depth 14. The DES keeps the fixed room and random keyed cells;
-- this hook emits only the depth-dependent monster declarations.
local directives = require("constants.vault_directives")

local handler = {}

-- Absolute depth is deliberate here: the source tests you.absdepth(),
-- unlike most Snake scripts that compare local branch depth.
function handler.configure(api)
    if api:absolute_depth() > 14 then
        api:emit(directives.KMONS,
            "D = patrolling Aizul, patrolling nagaraja")
        api:emit(directives.KMONS,
            "E = guardian serpent / nagaraja")
    else
        api:emit(directives.KMONS,
            "D = patrolling Aizul, patrolling guardian serpent")
        api:emit(directives.KMONS,
            "E = naga mage / guardian serpent")
    end
end

return handler
