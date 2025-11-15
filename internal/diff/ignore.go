package diff

import (
	"encoding/json"
	"fmt"
	"os"
)

// IgnoreManager manages ignore rules from ignore.json
type IgnoreManager struct {
	rules map[string]string // path -> comment
}

// NewIgnoreManager creates a new ignore manager
func NewIgnoreManager() *IgnoreManager {
	return &IgnoreManager{
		rules: make(map[string]string),
	}
}

// LoadFromFile loads ignore rules from a JSON file
func (im *IgnoreManager) LoadFromFile(filePath string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			// ignore.json doesn't exist, that's fine
			return nil
		}
		return fmt.Errorf("failed to read ignore file: %w", err)
	}

	type ignoreRule struct {
		Path    string `json:"path"`
		Comment string `json:"comment"`
	}

	var rules []ignoreRule
	if err := json.Unmarshal(data, &rules); err != nil {
		return fmt.Errorf("failed to parse ignore file: %w", err)
	}

	for _, rule := range rules {
		im.rules[rule.Path] = rule.Comment
	}

	return nil
}

// IsIgnored checks if a path is in the ignore list
func (im *IgnoreManager) IsIgnored(path string) bool {
	_, exists := im.rules[path]
	return exists
}

// GetReason returns the reason for ignoring a path
func (im *IgnoreManager) GetReason(path string) string {
	return im.rules[path]
}

// RuleCount returns the number of ignore rules loaded
func (im *IgnoreManager) RuleCount() int {
	return len(im.rules)
}
