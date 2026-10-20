-- Shared serial tags keep controller requests tied to their authored map
-- families without scattering literal selector strings through Lua policy.
local tags = {
    SERIAL_NICO_SUBWAY = "serial_nico_subway",
}

return tags
