-- Cheibriados gates each punishment through religion.cc:get_tension. The
-- current Lua tension evaluator is private to Seal Doors, so a separate
-- guess here would change both severity odds and penance reduction.
local cheibriados = {}

-- Keep this branch explicit until the saved combat tension owner exposes
-- the source score; a generic Slow or stat drain would misrepresent wrath.
function cheibriados.apply()
    error("unimplemented Cheibriados tension-based wrath")
end

return cheibriados
