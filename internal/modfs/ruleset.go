// Package modfs resolves bundled Lua and ordered file overlays into one
// immutable, hash-identified ruleset for a game session.
package modfs

import (
	"crypto/sha256"
	"embed"
	"encoding/binary"
	"encoding/hex"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

//go:embed builtin
var builtin embed.FS

// Ruleset is the exact Lua source tree used to start a game. It owns copies
// of the source bytes so changes to an overlay after Load cannot change a run.
type Ruleset struct {
	files       map[string][]byte
	paths       []string
	changes     []string
	hash        string
	bundledHash string
}

// Load resolves the bundled Lua tree with sparse overlays in argument order.
// The last layer containing a relative path supplies its bytes.
func Load(overlayDirs ...string) (Ruleset, error) {
	root, err := fs.Sub(builtin, "builtin")

	if err != nil {
		return Ruleset{}, fmt.Errorf("bundled Lua root: %w", err)
	}

	bundled, err := readBundled(root)

	if err != nil {
		return Ruleset{}, err
	}

	effective := copyFiles(bundled)

	for _, overlayDir := range overlayDirs {
		if overlayDir == "" {
			return Ruleset{}, fmt.Errorf("Lua overlay root must not be empty")
		}

		if err := applyOverlay(effective, overlayDir); err != nil {
			return Ruleset{}, fmt.Errorf("Lua overlay %q: %w", overlayDir, err)
		}

		if err := checkCaseCollisions(effective); err != nil {
			return Ruleset{}, fmt.Errorf("Lua overlay %q: %w", overlayDir, err)
		}
	}

	if err := checkCaseCollisions(effective); err != nil {
		return Ruleset{}, err
	}

	paths := sortedPaths(effective)
	changes := changedPaths(bundled, effective)

	return Ruleset{
		files:       effective,
		paths:       paths,
		changes:     changes,
		hash:        hashFiles(effective),
		bundledHash: hashFiles(bundled),
	}, nil
}

// ReadFile returns a copy so callers cannot alter a loaded ruleset.
func (r Ruleset) ReadFile(name string) ([]byte, error) {
	if !fs.ValidPath(name) ||
		name == "." ||
		!strings.HasSuffix(name, ".lua") {
		return nil, fmt.Errorf("invalid Lua path %q", name)
	}

	data, found := r.files[name]

	if !found {
		return nil, fs.ErrNotExist
	}

	return slices.Clone(data), nil
}

func (r Ruleset) Paths() []string {
	return slices.Clone(r.paths)
}

func (r Ruleset) Changes() []string {
	return slices.Clone(r.changes)
}

// FileHash identifies the bytes loaded at one normalized Lua path.
type FileHash struct {
	Path   string `json:"path"`
	SHA256 string `json:"sha256"`
}

func (r Ruleset) Manifest() []FileHash {
	manifest := make([]FileHash, 0, len(r.paths))

	for _, name := range r.paths {
		sum := sha256.Sum256(r.files[name])

		manifest = append(manifest, FileHash{
			Path:   name,
			SHA256: hex.EncodeToString(sum[:]),
		})
	}

	return manifest
}

func (r Ruleset) Hash() string {
	return r.hash
}

func (r Ruleset) BundledHash() string {
	return r.bundledHash
}

func (r Ruleset) Vanilla() bool {
	return r.hash == r.bundledHash
}

func readBundled(root fs.FS) (map[string][]byte, error) {
	files := make(map[string][]byte)

	err := fs.WalkDir(root, ".", func(name string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}

		if entry.IsDir() {
			return nil
		}

		if !validLuaPath(name) {
			return fmt.Errorf("invalid bundled Lua path %q", name)
		}

		data, err := fs.ReadFile(root, name)

		if err != nil {
			return err
		}

		files[name] = data

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("read bundled Lua: %w", err)
	}

	if _, found := files["init.lua"]; !found {
		return nil, fmt.Errorf("bundled Lua has no init.lua")
	}

	return files, nil
}

func applyOverlay(files map[string][]byte, root string) error {
	info, err := os.Lstat(root)

	if err != nil {
		return fmt.Errorf("Lua overlay: %w", err)
	}

	if !info.IsDir() || info.Mode()&os.ModeSymlink != 0 {
		return fmt.Errorf("Lua overlay root is not a real directory")
	}

	return filepath.WalkDir(root, func(full string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}

		if full == root {
			return nil
		}

		if entry.Type()&os.ModeSymlink != 0 {
			return fmt.Errorf("Lua overlay contains symlink %q", full)
		}

		if entry.IsDir() {
			return nil
		}

		if !entry.Type().IsRegular() {
			return fmt.Errorf("Lua overlay contains nonregular file %q", full)
		}

		relative, err := filepath.Rel(root, full)

		if err != nil {
			return err
		}

		name := filepath.ToSlash(relative)

		if !validLuaPath(name) {
			return fmt.Errorf("invalid Lua overlay path %q", name)
		}

		data, err := os.ReadFile(full)

		if err != nil {
			return err
		}

		files[name] = data

		return nil
	})
}

func validLuaPath(name string) bool {
	return fs.ValidPath(name) &&
		name != "." &&
		strings.HasSuffix(name, ".lua")
}

func checkCaseCollisions(files map[string][]byte) error {
	folded := make(map[string]string, len(files))

	for name := range files {
		key := strings.ToLower(name)

		if previous, found := folded[key]; found && previous != name {
			return fmt.Errorf("Lua paths differ only by case: %q and %q", previous, name)
		}

		folded[key] = name
	}

	return nil
}

func copyFiles(source map[string][]byte) map[string][]byte {
	files := make(map[string][]byte, len(source))

	for name, data := range source {
		files[name] = slices.Clone(data)
	}

	return files
}

func sortedPaths(files map[string][]byte) []string {
	paths := make([]string, 0, len(files))

	for name := range files {
		paths = append(paths, name)
	}

	slices.Sort(paths)

	return paths
}

func changedPaths(bundled, effective map[string][]byte) []string {
	changes := make([]string, 0)

	for name, data := range effective {
		original, found := bundled[name]

		if !found || !slices.Equal(original, data) {
			changes = append(changes, name)
		}
	}

	slices.Sort(changes)

	return changes
}

// Hash includes path lengths as well as names and source hashes so the
// manifest cannot be confused by a different file split or concatenation.
func hashFiles(files map[string][]byte) string {
	hash := sha256.New()

	for _, name := range sortedPaths(files) {
		writeHashField(hash, []byte(name))

		contentHash := sha256.Sum256(files[name])
		writeHashField(hash, contentHash[:])
	}

	return hex.EncodeToString(hash.Sum(nil))
}

func writeHashField(hash interface{ Write([]byte) (int, error) }, data []byte) {
	var length [8]byte

	binary.BigEndian.PutUint64(length[:], uint64(len(data)))
	_, _ = hash.Write(length[:])
	_, _ = hash.Write(data)
}
