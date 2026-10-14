package character

// Roller supplies named, saveable random streams to character rules.
type Roller interface {
	Intn(stream string, bound int) (int, error)
}
