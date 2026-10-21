-- A clear door is optional; later NSUBST still chooses each hall branch.
local directives = require("constants.vault_directives")

local handler = {}

-- The source coin flip consumes one draw even when it emits no door.
local function configure(api)
    if api:one_in(2) then
        api:emit(directives.KFEAT, "+ = closed_clear_door")
    end
end

handler.configure = configure

return handler
