-- The arrival hook substitutes a map glyph when expanded by the vault parser.
-- Example: choose_subst emits SUBST 1 = . for the test arrival map.

local handler = {}

-- Emit a terrain substitution through the actual vault hook API, proving a
-- layered arrival script participates in DES expansion.
local function choose_subst(api)
    api:emit("SUBST", "1 = .")
end

handler.choose_subst = choose_subst

return handler
