-- Xom delegates wrath to the large xom_acts event engine. The Go port
-- has Xom's worship and conduct state but not that event engine yet.
local xom = {}

-- The source derives act severity from piety before entering xom_acts.
-- Do not substitute a generic curse or reroll: that changes the card's
-- odds, effects, and penance. The future Xom slice owns this whole action.
function xom.apply()
    error("unimplemented Xom action engine for divine wrath")
end

return xom
