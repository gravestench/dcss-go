-- Theory of operation: the oklob entry scales its central defenders with
-- absolute Dungeon depth. The authored MAP and stair remain in DES; this
-- hook inserts only the source substitutions at their original position.
local directives = require("constants.vault_directives")

local handler = {}

-- The source switches from safer early entrances to denser oklob clusters.
local function configure(api)
    local depth = api:absolute_depth()

    if depth < 10 then
        api:emit(directives.SUBST, "A = 11.")
        api:emit(directives.SUBST, "B = 2.")

        return
    end

    api:emit(directives.SUBST, "A = 2")

    if depth < 11 then
        api:emit(directives.NSUBST, "B = 2 = 3... / * = 2.")
    else
        api:emit(directives.NSUBST, "B = 3 = 33... / * = 2.")
    end
end

handler.configure = configure

return handler
