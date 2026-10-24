package game

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
)

// A normal sling bullet must reach the rat behind a friendly plant. The
// same ray must contact a hostile plant before it can reach that rat.
func TestFedhasShotPassesAlliedPlant(t *testing.T) {
	cases := []struct {
		name      string
		attitude  string
		underfoot bool
	}{
		{
			name:     "friendly",
			attitude: "friendly",
		},

		{
			name:     "hostile",
			attitude: "hostile",
		},

		{
			name:      "underfoot",
			attitude:  "friendly",
			underfoot: true,
		},
	}

	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			g := newStepGame(t)
			readyFedhasWorshipper(t, g)
			cloneRatOnRay(t, g, 2, 1)

			plant, found := g.levels[1].ActorAt(2, 1)

			if !found {
				t.Fatal("fixture plant has no position")
			}

			if _, err := g.stores.Actors.Set(plant, ecs.Actor{
				KindID: "MONS_BALLISTOMYCETE",
				Speed:  10,
			}); err != nil {
				t.Fatal(err)
			}

			_, err := g.scripts.Components()["religion.fedhas_plant"].Set(
				plant,
				map[string]any{
					"attitude":  test.attitude,
					"attempted": true,
				},
			)

			if err != nil {
				t.Fatal(err)
			}

			if test.underfoot {
				if err := g.levels[1].MoveActorShared(
					plant, 1, 1, false,
				); err != nil {
					t.Fatal(err)
				}
			}

			equipPlayerLauncher(t, g, "WPN_SLING")

			result, err := g.Step(Command{
				Kind: CommandFire,
				DX:   3,
			})

			if err != nil {
				t.Fatal(err)
			}

			plantContact := false
			ratContact := false
			protectedMessage := false

			for _, event := range result.Events {
				protectedMessage = protectedMessage ||
					strings.Contains(event.Text,
						"Fedhas protects your plant from harm")

				if !strings.Contains(event.Text, "sling bullet") {
					continue
				}

				plantContact = plantContact ||
					strings.Contains(event.Text, "ballistomycete")
				ratContact = ratContact ||
					strings.Contains(event.Text, "the rat")
			}

			if test.attitude == "friendly" {
				if plantContact || !ratContact ||
					(!test.underfoot && !protectedMessage) {
					t.Fatalf("protected shot: plant=%v rat=%v notice=%v",
						plantContact, ratContact, protectedMessage)
				}
			} else if !plantContact {
				t.Fatal("hostile plant did not intercept the shot")
			}
		})
	}
}
