-- A gold pile remembers whether Zin may tax it and whether that tax can
-- award piety. These names correspond to the source tithe_state enum.
local states = {
    DEFAULT = "default",
    NO_PIETY = "no_piety",
    FULL_TITHE = "full_tithe",
    NO_TITHE = "no_tithe",
}

return states
