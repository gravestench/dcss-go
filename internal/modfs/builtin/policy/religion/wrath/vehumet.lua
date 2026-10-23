-- Vehumet casts a level-scaled conjuration through a god avatar. The
-- ordinary monster spell caster cannot represent that avatar or its blame.
local vehumet = {}

-- god-wrath.cc obtains an avatar before choosing severity or a spell.
-- Reject this path before drawing rather than replacing it with direct damage.
function vehumet.apply()
    error("unimplemented Vehumet god-avatar spell wrath")
end

return vehumet
