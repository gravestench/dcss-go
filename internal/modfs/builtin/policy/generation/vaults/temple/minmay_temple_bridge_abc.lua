-- The bridge has three source water layouts. Seven of nine draws use the
-- broad channel; the other two each open a different narrow crossing.
local directives = require("constants.vault_directives")

local handler = {}

-- Draw once for the entire bridge so its punctuation glyphs form one
-- coherent channel instead of independently selected pieces.
local function configure(api)
    local draw = api:roll(9)

    if draw == 0 then
        api:emit(directives.SUBST, "'\"- = ., ;~ = w")
    elseif draw == 1 then
        api:emit(directives.SUBST, "\"; = ., '-b = w, ~ = b")
    else
        api:emit(directives.SUBST, "`~ = ., '\";b = w")
    end
end

handler.configure = configure

return handler
