local flame = {}

-- Flame contributes its field presence without a per-tick occupant effect.
-- Example: entering a flame marker calls no occupant damage hook; its field presence is the effect.
function flame.apply()
end

return flame
