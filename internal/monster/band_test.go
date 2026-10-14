package monster

import (
	"fmt"
	"testing"
)

type bandRoller struct {
	value int
	calls int
}

func (r *bandRoller) Intn(stream string, bound int) (int, error) {
	if stream != "bands" || bound != 3 {
		return 0, fmt.Errorf("unexpected band draw %q/%d", stream, bound)
	}

	r.calls++

	return r.value, nil
}

func TestJackalFollowerCountUsesExclusiveSourceUpperBound(t *testing.T) {
	for roll := 0; roll < 3; roll++ {
		roller := &bandRoller{value: roll}
		got, err := JackalFollowerCount(roller)

		if err != nil {
			t.Fatal(err)
		}

		if got != roll+1 || roller.calls != 1 {
			t.Fatalf("roll %d gave %d followers after %d draws", roll, got, roller.calls)
		}
	}

	if _, err := JackalFollowerCount(&bandRoller{value: 3}); err == nil {
		t.Fatal("accepted out-of-range follower draw")
	}
}
