#!/usr/bin/env python3

import sys
import json
import yaml
import re
from pathlib import Path

# Load input JSON from Claude Code
input_json = json.load(sys.stdin)
command = input_json["tool_input"]["command"]

# Load YAML policy
policy_path = Path.home() / ".claude/policies/bash_policy.yaml"
with open(policy_path, "r") as f:
    policy = yaml.safe_load(f)

normalized = command
if policy.get("settings", {}).get("normalize_whitespace", True):
    normalized = " ".join(command.split())

flags = re.IGNORECASE if policy.get("settings", {}).get("case_insensitive", True) else 0

# Check allowlist first
for rule in policy.get("allowlist", []):
    if re.search(rule["pattern"], normalized, flags):
        # Explicitly allowed
        sys.exit(0)

# Check blocklist
for rule in policy.get("blocklist", []):
    if re.search(rule["pattern"], normalized, flags):
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": rule["reason"],
                "matchedPattern": rule["pattern"]
            }
        }
        print(json.dumps(output))
        sys.exit(0)

# If nothing matched, allow execution
sys.exit(0)
