-- Theory of operation: the salamander stair guard changes its keyed
-- roster on Snake:1, Snake:2, and deeper floors. The weighted 'nothing'
-- terms preserve the source's chance of leaving a particular slot empty.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit both keyed slots from one local-depth branch so later DES KFEAT
-- and NSUBST process exactly the selected source expressions.
function handler.configure(api)
    local first
    local second

    if api:depth() < 2 then
        first = "1 = salamander mystic / salamander tyrant w:5"
        second = "2 = salamander / salamander mystic w:1 / nothing w:80"
    elseif api:depth() < 3 then
        first = "1 = salamander mystic / salamander tyrant"
        second = "2 = salamander / salamander mystic w:2 / nothing w:50"
    else
        first = "1 = salamander tyrant"
        second = "2 = salamander / salamander mystic w:5 / nothing w:45"
    end

    api:emit(directives.KMONS, first)
    api:emit(directives.KMONS, second)
end

return handler
