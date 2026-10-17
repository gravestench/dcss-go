package game

import "testing"

func TestSpectralCloudEmitsSummonedThing(t *testing.T) {
	g := newZapGame(t)
	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]
	x, y := -1, -1

	for dy := -3; dy <= 3 && x < 0; dy++ {
		for dx := -3; dx <= 3; dx++ {
			candidateX := position.X + dx
			candidateY := position.Y + dy

			if level.Walkable(candidateX, candidateY) {
				if _, occupied := level.ActorAt(candidateX, candidateY); !occupied {
					x, y = candidateX, candidateY
					break
				}
			}
		}
	}

	if x < 0 {
		t.Fatal("test level has no open cell near the player")
	}

	cloud, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["world.cloud"].Set(cloud,
		map[string]any{
			"kind_id":         "CLOUD_SPECTRAL",
			"level_id":        int64(position.LevelID),
			"x":               int64(x),
			"y":               int64(y),
			"decay_aut":       int64(1000),
			"source_actor_id": uint64(g.player),
			"kill_category":   "KC_YOU",
			"killer_type":     "KILL_YOU_MISSILE",
		}); err != nil {
		t.Fatal(err)
	}

	for range 30 {
		if _, err := g.scripts.Policy("world.cloud_field", map[string]any{
			"level_id":    int64(position.LevelID),
			"elapsed_aut": int64(10),
		}); err != nil {
			t.Fatal(err)
		}

		if err := g.scripts.ApplyPending(); err != nil {
			t.Fatal(err)
		}

		if _, occupied := level.ActorAt(x, y); occupied {
			for _, entity := range g.stores.Actors.Entities() {
				actor, _ := g.stores.Actors.Get(entity)

				if actor.KindID == "MONS_SPECTRAL_THING" &&
					g.scripts.Components()["magic.summon_undead"].Has(entity) {
					return
				}
			}
		}
	}

	t.Fatal("spectral cloud did not emit a sourced spectral thing")
}
