local monster_spells = {}

function monster_spells.effect(spell_id)
    local name = spell_id:match("^SPELL_(.+)$")

    if not name then
        error("invalid monster spell " .. tostring(spell_id))
    end

    -- A mod can add one effect file without editing a central spell switch.
    return require("policy.combat.monster_spells." .. name:lower())
end

return monster_spells
