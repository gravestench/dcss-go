package game

type cloudRecord struct {
	kindID string
	x      int
	y      int
	opaque bool
}

func (g *Game) cloudsOnLevel(levelID int) []cloudRecord {
	if g.scripts == nil {
		return nil
	}

	store := g.scripts.Components()["magic.cloud"]

	if store == nil {
		return nil
	}

	clouds := make([]cloudRecord, 0)

	for _, entity := range store.Entities() {
		component, found := store.Get(entity)

		if !found {
			continue
		}

		fields, err := component.Snapshot()

		if err != nil {
			panic(err)
		}

		if int(fields["level_id"].(int64)) != levelID ||
			fields["expires_aut"].(int64) <= int64(g.currentAut) {
			continue
		}

		clouds = append(clouds, cloudRecord{
			kindID: fields["kind_id"].(string),
			x:      int(fields["x"].(int64)),
			y:      int(fields["y"].(int64)),
			opaque: fields["opaque"].(bool),
		})
	}

	return clouds
}

func (g *Game) opaqueClouds(levelID int) map[point]bool {
	opaque := make(map[point]bool)

	for _, cloud := range g.cloudsOnLevel(levelID) {
		if cloud.opaque {
			cell := point{
				x: cloud.x,
				y: cloud.y,
			}

			opaque[cell] = true
		}
	}

	return opaque
}
