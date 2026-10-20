-- Shared serial tags keep controller requests tied to their authored map
-- families without scattering literal selector strings through Lua policy.
local tags = {
    SERIAL_NICO_SUBWAY = "serial_nico_subway",
    SERIAL_DEMONIC = "serial_demonic",
    SERIAL_UNDEAD = "serial_undead",
    SERIAL_PARK = "serial_park",
    SERIAL_PARK_MINIVAULT = "serial_park_minivault",
}

return tags
