package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

func TestShoalsTideKeepsAuthoredElevationAcrossCellChanges(t *testing.T) {
	world := akara.NewWorld()
	positions := akara.Register[ecs.Position](world)
	level, err := NewLevel(1, [][]terrain.ID{
		{
			terrain.DeepWater,
			terrain.Floor,
			terrain.RockWall,
		},
	}, positions)

	if err != nil {
		t.Fatal(err)
	}

	level.InitShoalsTide()

	heights := [][]int{
		{
			-31,
			12,
			135,
		},
	}

	if err := level.SetShoalsHeights(heights); err != nil {
		t.Fatal(err)
	}

	if err := level.SetCell(1, 0, terrain.ShallowWater); err != nil {
		t.Fatal(err)
	}

	height, ok := level.ShoalsHeightAt(1, 0)

	if !ok || height != 12 {
		t.Fatalf("temporary water changed authored elevation: %d, %v", height, ok)
	}

	if err := level.SetShoalsTideClock(21, -2, 100); err != nil {
		t.Fatal(err)
	}

	record := level.shoalsTideRecord()

	record.Heights[0][1] = 99

	if height, _ := level.ShoalsHeightAt(1, 0); height != 12 {
		t.Fatal("save record aliases the live elevation grid")
	}

	if err := level.SetShoalsTideClock(0, 2, 90); err == nil {
		t.Fatal("tide clock moved backwards")
	}
}

func TestLuaShoalsHeightsPreservesIntermediateElevation(t *testing.T) {
	heights, err := luaShoalsHeights([]any{
		[]any{
			int64(-31),
			int64(12),
			int64(135),
		},
	})

	if err != nil {
		t.Fatal(err)
	}

	want := [][]int{
		{
			-31,
			12,
			135,
		},
	}

	if !reflect.DeepEqual(heights, want) {
		t.Fatalf("heightmap = %v", heights)
	}

	if _, err := luaShoalsHeights([]any{[]any{12.5}}); err == nil {
		t.Fatal("fractional Shoals elevation accepted")
	}
}
