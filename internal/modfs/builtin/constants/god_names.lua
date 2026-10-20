-- Human-facing god names are kept beside the shared IDs. Saved altars store
-- IDs only, so changing presentation cannot change an existing run's owner.
-- This is the current DCSS pantheon; worship rules will use these same IDs.
local gods = require("constants.gods")

local names = {
    [gods.NO_GOD] = "no god",
    [gods.ZIN] = "Zin",
    [gods.SHINING_ONE] = "the Shining One",
    [gods.KIKUBAAQUDGHA] = "Kikubaaqudgha",
    [gods.YREDELEMNUL] = "Yredelemnul",
    [gods.VEHUMET] = "Vehumet",
    [gods.OKAWARU] = "Okawaru",
    [gods.MAKHLEB] = "Makhleb",
    [gods.SIF_MUNA] = "Sif Muna",
    [gods.TROG] = "Trog",
    [gods.NEMELEX_XOBEH] = "Nemelex Xobeh",
    [gods.ELYVILON] = "Elyvilon",
    [gods.XOM] = "Xom",
    [gods.LUGONU] = "Lugonu",
    [gods.BEOGH] = "Beogh",
    [gods.FEDHAS] = "Fedhas",
    [gods.CHEIBRIADOS] = "Cheibriados",
    [gods.ASHENZARI] = "Ashenzari",
    [gods.DITHMENOS] = "Dithmenos",
    [gods.GOZAG] = "Gozag",
    [gods.QAZLAL] = "Qazlal",
    [gods.RU] = "Ru",
    [gods.USKAYAW] = "Uskayaw",
    [gods.HEPLIAKLQANA] = "Hepliaklqana",
    [gods.WU_JIAN] = "Wu Jian",
    [gods.IGNIS] = "Ignis",
    [gods.JIYVA] = "Jiyva",
}

return names
