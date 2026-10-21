-- Shoals keeps elevation apart from terrain so a flooded floor can dry out.
-- These bands mirror the source terrain thresholds and are shared by the
-- island layout and authored-vault overlay.
return {
    DEEP = -33,
    SHALLOW = -30,
    FLOOR = 0,
    ROCK = 135,
    TIDE_IMMUNE = 400,
}
