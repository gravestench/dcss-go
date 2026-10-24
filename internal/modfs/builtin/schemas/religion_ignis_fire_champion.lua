-- Ignis's permanent anointment belongs to the living monster. Combat,
-- movement, and perception read this one saved marker independently.
register.component{
    id = "religion.ignis_fire_champion",
    version = 1,
    fields = {
        active = {
            type = "bool",
            default = true,
        },
    },
}
