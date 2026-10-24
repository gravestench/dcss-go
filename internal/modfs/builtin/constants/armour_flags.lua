-- These flags describe armour properties that resistance and stealth rules can inspect.

local armour_flags = {
    RES_FIRE = "ARMF_RES_FIRE",
    RES_COLD = "ARMF_RES_COLD",
    RES_ELECTRICITY = "ARMF_RES_ELEC",
    RES_POISON = "ARMF_RES_POISON",
    VUL_FIRE = "ARMF_VUL_FIRE",
    VUL_COLD = "ARMF_VUL_COLD",
    RES_CORROSION = "ARMF_RES_CORR",
    RES_STEAM = "ARMF_RES_STEAM",
    RES_NEGATIVE_ENERGY = "ARMF_RES_NEG",
    WILLPOWER = "ARMF_WILLPOWER",
    STEALTH = "ARMF_STEALTH",
}

return armour_flags
