package save

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

func Write(path string, snapshot Snapshot) (err error) {
	if snapshot.Version != Version {
		return fmt.Errorf("unsupported save version %d", snapshot.Version)
	}
	file, err := os.CreateTemp(filepath.Dir(path), ".dcrawl-save-*")
	if err != nil {
		return err
	}
	defer os.Remove(file.Name())
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err = encoder.Encode(snapshot); err != nil {
		file.Close()
		return err
	}
	if err = file.Sync(); err != nil {
		file.Close()
		return err
	}
	if err = file.Close(); err != nil {
		return err
	}
	if err = os.Rename(file.Name(), path); err != nil {
		return err
	}
	return nil
}

func Read(path string) (Snapshot, error) {
	file, err := os.Open(path)
	if err != nil {
		return Snapshot{}, err
	}
	defer file.Close()
	decoder := json.NewDecoder(file)
	decoder.DisallowUnknownFields()
	var snapshot Snapshot
	if err := decoder.Decode(&snapshot); err != nil {
		return Snapshot{}, fmt.Errorf("decode save: %w", err)
	}
	if snapshot.Version != Version {
		return Snapshot{}, fmt.Errorf("unsupported save version %d", snapshot.Version)
	}
	var extra any
	if err := decoder.Decode(&extra); err != io.EOF {
		return Snapshot{}, fmt.Errorf("trailing save data")
	}
	return snapshot, nil
}
