package tools

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os/exec"
)

// ExecuteHCL2JSON runs hcl2json on the given file and returns parsed JSON
func ExecuteHCL2JSON(filePath string) (map[string]interface{}, error) {
	cmd := exec.Command("hcl2json", filePath)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("hcl2json failed on %s: %s: %w", filePath, stderr.String(), err)
	}

	var result map[string]interface{}
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		return nil, fmt.Errorf("failed to parse hcl2json output from %s: %w", filePath, err)
	}

	return result, nil
}

// JDDiff represents a single diff from jd output (RFC 6902 format)
type JDDiff struct {
	Path  string      `json:"path"`
	Op    string      `json:"op"`
	From  interface{} `json:"from,omitempty"`
	Value interface{} `json:"value,omitempty"`
}

// ExecuteJD runs jd to compare two JSON files and returns diffs as structured data
func ExecuteJD(baseJSONPath, targetJSONPath string) ([]JDDiff, error) {
	cmd := exec.Command("jd", "-f", "patch", baseJSONPath, targetJSONPath)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// jd returns exit code 1 when differences are found, which is normal
	_ = cmd.Run()

	// Parse jd JSON output into structured diffs (RFC 6902 format)
	var patches []JDDiff
	if err := json.Unmarshal(stdout.Bytes(), &patches); err != nil {
		return nil, fmt.Errorf("failed to parse jd output: %w", err)
	}

	// Filter out "test" operations and merge remove+add into replace
	var diffs []JDDiff
	removesByPath := make(map[string]*JDDiff)

	for _, patch := range patches {
		if patch.Op == "test" {
			continue // Skip test operations
		}

		if patch.Op == "remove" {
			// Store remove operations to potentially merge with add
			removesByPath[patch.Path] = &patch
		} else if patch.Op == "add" {
			// Check if there's a corresponding remove for this path
			if remove, exists := removesByPath[patch.Path]; exists {
				// Merge remove+add into replace
				diffs = append(diffs, JDDiff{
					Path:  patch.Path,
					Op:    "replace",
					From:  remove.Value,
					Value: patch.Value,
				})
				delete(removesByPath, patch.Path)
			} else {
				// No corresponding remove, just add
				diffs = append(diffs, patch)
			}
		} else {
			// Other operations (replace, etc)
			diffs = append(diffs, patch)
		}
	}

	// Add any remaining remove operations that didn't have a corresponding add
	for _, remove := range removesByPath {
		diffs = append(diffs, *remove)
	}

	return diffs, nil
}
