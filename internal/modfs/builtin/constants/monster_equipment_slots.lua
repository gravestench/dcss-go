-- Monster equipment slots persist on core.equipped item components.
-- Beogh gifts and corpse reclamation share these IDs with monster inventory.
local slots = {
    WEAPON = "weapon",
    ALTERNATE_WEAPON = "alternate_weapon",
    BODY = "body",
    SHIELD = "shield",
    MISSILE = "missile",
}

-- A corpse can remember only slots the inventory save owner understands.
function slots.valid(value)
    return value == slots.WEAPON or
        value == slots.ALTERNATE_WEAPON or
        value == slots.BODY or
        value == slots.SHIELD or
        value == slots.MISSILE
end

return slots
