package game

import "testing"

func TestUnitBoundDoesNotAdvanceNamedRandomStream(t *testing.T) {
	withUnitDraw := NewRNGStreams(42)
	untouched := NewRNGStreams(42)

	unit, err := withUnitDraw.Intn("mutation", 1)

	if err != nil {
		t.Fatal(err)
	}

	if unit != 0 {
		t.Fatalf("unit-bound result = %d", unit)
	}

	if len(withUnitDraw.States()) != 0 {
		t.Fatal("unit-bound draw advanced the mutation stream")
	}

	afterUnit, err := withUnitDraw.Intn("mutation", 100)

	if err != nil {
		t.Fatal(err)
	}

	withoutUnit, err := untouched.Intn("mutation", 100)

	if err != nil {
		t.Fatal(err)
	}

	if afterUnit != withoutUnit {
		t.Fatalf("unit-bound draw changed continuation: %d != %d",
			afterUnit, withoutUnit)
	}
}
