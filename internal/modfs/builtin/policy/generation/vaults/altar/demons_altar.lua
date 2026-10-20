-- Theory of operation: demons_altar keeps its ordinary three monster
-- slots, but only deep Dungeon floors may rearrange the stronger demons.
-- The source shuffles and narrows slots 1 and 2 at absolute depth ten.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the whole deep-floor group together so shallower maps keep their
-- default monster layout and consume no deep-only shuffle draw.
local function deepen_demons(api)
    if api:absolute_depth() <= 9 then
        return
    end

    api:emit(directives.SHUFFLE, "123")
    api:emit(directives.NSUBST, "1 = 1:1 / *:.")
    api:emit(directives.NSUBST, "2 = 1:2 / *:.")
end

handler.deepen_demons = deepen_demons

return handler
