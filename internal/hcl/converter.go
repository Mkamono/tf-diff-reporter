package hcl

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/Mkamono/tf-diff-reporter/internal/tools"
)

// ConvertDirectory converts all HCL/tf files in a directory to a single merged JSON file
// Returns path to temporary JSON file
func ConvertDirectory(dirPath string) (string, error) {
	entries, err := os.ReadDir(dirPath)
	if err != nil {
		return "", fmt.Errorf("failed to read directory %s: %w", dirPath, err)
	}

	merged := make(map[string]interface{})

	// Process all .tf and .hcl files
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		ext := filepath.Ext(entry.Name())
		if ext != ".tf" && ext != ".hcl" {
			continue
		}

		converted, err := tools.ExecuteHCL2JSON(filepath.Join(dirPath, entry.Name()))
		if err != nil {
			return "", err
		}

		mergeJSON(merged, converted)
	}

	// Write merged JSON to temporary file
	tmpFile, err := os.CreateTemp("", "tfdr-merged-*.json")
	if err != nil {
		return "", fmt.Errorf("failed to create temporary file: %w", err)
	}
	tmpPath := tmpFile.Name()
	tmpFile.Close()

	data, _ := json.Marshal(merged)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return "", fmt.Errorf("failed to write JSON: %w", err)
	}

	return tmpPath, nil
}

// mergeJSON recursively merges src into dst
func mergeJSON(dst, src map[string]interface{}) {
	for key, srcVal := range src {
		if dstVal, exists := dst[key]; exists {
			if dstMap, ok := dstVal.(map[string]interface{}); ok {
				if srcMap, ok := srcVal.(map[string]interface{}); ok {
					mergeJSON(dstMap, srcMap)
				}
			}
		} else {
			dst[key] = srcVal
		}
	}
}
