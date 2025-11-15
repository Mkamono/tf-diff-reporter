package tools

import (
	"fmt"
	"os/exec"
)

// CheckToolAvailable checks if a tool is available in PATH
func CheckToolAvailable(toolName string) error {
	_, err := exec.LookPath(toolName)
	if err != nil {
		return fmt.Errorf("tool '%s' not found in PATH: %w", toolName, err)
	}
	return nil
}

// CheckRequiredTools checks if all required tools are available
func CheckRequiredTools() error {
	requiredTools := []string{"hcl2json", "jd"}

	for _, tool := range requiredTools {
		if err := CheckToolAvailable(tool); err != nil {
			return err
		}
	}

	return nil
}
