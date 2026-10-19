local mist = {}

-- Mist's field behavior is handled by clouds; an occupant receives no direct tick effect.
-- Example: walking through mist leaves actor HP and status unchanged in this hook.
function mist.apply()
end

return mist
