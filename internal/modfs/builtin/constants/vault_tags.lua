-- Shared serial tags keep controller requests tied to their authored map
-- families without scattering literal selector strings through Lua policy.
local tags = {
    SERIAL_NICO_SUBWAY = "serial_nico_subway",
    SERIAL_DEMONIC = "serial_demonic",
    SERIAL_UNDEAD = "serial_undead",
    SERIAL_PARK = "serial_park",
    SERIAL_PARK_MINIVAULT = "serial_park_minivault",
    SERIAL_GNOLL_CAMP = "serial_gnoll_camp",
    SERIAL_CO_WINDOW_SMALL = "serial_co_window_small",
    SERIAL_CO_WINDOW_COMMON = "serial_co_window_common",
    SERIAL_CO_WINDOW_RARE = "serial_co_window_rare",
    SERIAL_GLASS = "serial_glass",
    SERIAL_GLASS_RARE = "serial_glass_rare",
    SERIAL_SIGILS = "serial_sigils",
    SERIAL_ICE = "serial_ice",
    CHANCE_ICECAVE = "chance_icecave",
    UNIQ_ICECV = "uniq_icecv",
    SERIAL_FOREST = "serial_forest",
}

return tags
