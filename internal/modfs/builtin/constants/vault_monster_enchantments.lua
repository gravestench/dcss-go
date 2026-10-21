-- Names accepted by the pinned DES monster perm_ench modifier. These are
-- source status names, separate from the engine's runtime status components.
local enchantments = {
    BLIND = "blind",
    CONFUSION = "confusion",
    CORONA = "corona",
    DUMB = "dumb",
    MAD = "mad",
    MUTE = "mute",
    PARALYSIS = "paralysis",
    PETRIFIED = "petrified",
    SLOW = "slow",
}

enchantments.VALID = {}

for _, value in pairs(enchantments) do
    if type(value) == "string" then
        enchantments.VALID[value] = true
    end
end

return enchantments
