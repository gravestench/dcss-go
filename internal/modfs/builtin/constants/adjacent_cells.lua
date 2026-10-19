-- Eight offsets enumerate neighbors clockwise by rows; the center cell is deliberately absent.

-- Eight-neighbor offsets in row-major order from the upper-left cell.
return {
    { -1, -1 },
    { 0, -1 },
    { 1, -1 },
    { -1, 0 },
    { 1, 0 },
    { -1, 1 },
    { 0, 1 },
    { 1, 1 },
}
