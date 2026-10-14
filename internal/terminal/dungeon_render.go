package terminal

import "dcrawl-go/internal/game"

// dungeonRenderer projects the read-only level view into the map pane.
type dungeonRenderer struct {
	canvas        *Canvas
	region        Region
	view          game.View
	policy        presentationPolicy
	centerX       int
	centerY       int
	terrainColors map[game.CellView]Color
	entityColors  map[string]Color
}

func drawDungeon(canvas *Canvas, region Region, view game.View, policy presentationPolicy) {
	if view.Width <= 0 {
		return
	}

	renderer := dungeonRenderer{
		canvas:        canvas,
		region:        region,
		view:          view,
		policy:        policy,
		centerX:       region.X + region.W/2,
		centerY:       region.Y + region.H/2,
		terrainColors: make(map[game.CellView]Color),
		entityColors:  make(map[string]Color),
	}

	renderer.drawTerrain()
	renderer.drawEntities()
}

func (r dungeonRenderer) drawTerrain() {
	for index, cell := range r.view.Cells {
		if cell.State == game.Unknown {
			continue
		}

		x := index % r.view.Width
		y := index / r.view.Width
		screenX, screenY, visible := r.screenPoint(x, y)

		if !visible {
			continue
		}

		r.canvas.Put(screenX, screenY, cell.Glyph, r.terrainColor(cell), Black)
	}
}

func (r dungeonRenderer) terrainColor(cell game.CellView) Color {
	if color, found := r.terrainColors[cell]; found {
		return color
	}

	result := runPresentation(r.policy, "presentation.terrain_color", map[string]any{
		"state": int(cell.State),
		"glyph": string(cell.Glyph),
	})

	color := policyColor(result["fg"])

	r.terrainColors[cell] = color

	return color
}

func (r dungeonRenderer) drawEntities() {
	// Draw the player last, even when the view lists it before a floor item.
	for _, playerPass := range []bool{false, true} {
		for _, entity := range r.view.Entities {
			if (entity.Role == "player") != playerPass {
				continue
			}

			r.drawEntity(entity)
		}
	}
}

func (r dungeonRenderer) drawEntity(entity game.EntityView) {
	screenX, screenY, visible := r.screenPoint(entity.X, entity.Y)

	if !visible {
		return
	}

	r.canvas.Put(screenX, screenY, entity.Glyph, r.entityColor(entity), Black)
}

func (r dungeonRenderer) entityColor(entity game.EntityView) Color {
	key := entity.Role + ":" + entity.KindID

	if color, found := r.entityColors[key]; found {
		return color
	}

	result := runPresentation(r.policy, "presentation.entity_color", map[string]any{
		"role":    entity.Role,
		"kind_id": entity.KindID,
	})

	color := policyColor(result["fg"])

	r.entityColors[key] = color

	return color
}

func (r dungeonRenderer) screenPoint(x, y int) (int, int, bool) {
	screenX := r.centerX + x - r.view.PlayerX
	screenY := r.centerY + y - r.view.PlayerY

	inX := screenX >= r.region.X && screenX < r.region.X+r.region.W
	inY := screenY >= r.region.Y && screenY < r.region.Y+r.region.H

	return screenX, screenY, inX && inY
}
