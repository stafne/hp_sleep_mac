# Config Template Management Guide

## Overview

The HP Py Sleep app uses a **two-file configuration system**:

1. **`hp_processor_config.json`** - The active configuration file (user's current settings)
2. **`default_config_template.json`** - The template used to create new config files

Both files are stored in: `~/Library/Application Support/HP Py Sleep/`

## How It Works

### Priority Order (Template Search)

When the app needs to create a new config file, it searches for the template in this order:

```
1. ~/Library/Application Support/HP Py Sleep/default_config_template.json
   ↳ User-maintained, most current
   
2. PyInstaller _MEIPASS directory
   ↳ Bundled with compiled app
   
3. App bundle Resources directory
   ↳ Alternative bundled location
   
4. Project root (development only)
   ↳ For running from source
```

### Why Library Folder First?

✅ **User can update templates** without rebuilding the app  
✅ **Templates stay current** across app updates  
✅ **Easy to customize** for different users/machines  
✅ **Shared templates** in multi-user environments  

## File Locations

### User's System
```
~/Library/Application Support/HP Py Sleep/
├── hp_processor_config.json          # Active config (user's settings)
├── default_config_template.json      # Template (for new configs)
└── hp_py_sleep.log                   # Log file
```

### Compiled App (Fallback)
```
hp_py_sleep_mac.app/Contents/MacOS/_internal/
└── default_config_template.json      # Bundled template
```

### Development
```
/path/to/project/
└── default_config_template.json      # Source template
```

## Usage Scenarios

### Scenario 1: First-Time User

**User**: Fresh install, no files in Library folder  
**Template Source**: Bundled with app  
**Result**: Template copied from app bundle to Library folder, then used to create config

```
1. App checks: ~/Library/Application Support/HP Py Sleep/hp_processor_config.json → NOT FOUND
2. Searches for template:
   - ~/Library/.../default_config_template.json → NOT FOUND
   - App bundle template → FOUND ✓
3. Copies to: ~/Library/.../hp_processor_config.json
4. Creates: ~/Library/.../default_config_template.json (for future use)
```

### Scenario 2: User Wants Custom Defaults

**User**: Wants different default event types for all new projects  
**Template Source**: User-edited template in Library folder  
**Result**: Future configs use customized template

```
1. User edits: ~/Library/.../default_config_template.json
2. Adds custom event types, state types, etc.
3. Deletes: ~/Library/.../hp_processor_config.json (to test)
4. Restarts app
5. App finds template in Library folder → Uses it ✓
6. New config has user's customizations
```

### Scenario 3: App Update

**User**: Updates to newer version  
**Template Source**: User's existing template in Library folder  
**Result**: User's custom template takes priority

```
1. New app version has updated bundled template
2. User's config file exists → preserved ✓
3. User's template exists → takes priority ✓
4. App uses: ~/Library/.../default_config_template.json
5. Bundled template ignored (fallback only)
```

### Scenario 4: Reset to Defaults

**User**: Wants to reset configuration to defaults  
**Action**: Delete active config, keep template  
**Result**: New config created from template

```bash
# Option A: Reset to user's template
rm ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json
# Restart app → uses existing template

# Option B: Reset to app's bundled defaults
rm ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json
rm ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json
# Restart app → uses bundled template, creates both files
```

## Updating the Template

### Method 1: Edit Directly (Recommended)

```bash
# Open template in editor
nano ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json

# Or use JSON editor
open -a TextEdit ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json
```

**Example: Add custom event type**
```json
{
  "event_types": {
    "Start": "green",
    "Stop": "red",
    "Error": "orange",
    "Custom Event": "purple",
    "My Event": "cyan"
  }
}
```

### Method 2: Copy from Active Config

If you've customized your active config and want to make it the template:

```bash
# Copy active config to template
cp ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json \
   ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json

# Optional: Update the created_by field
# (Open in editor and change "created_by" value)
```

### Method 3: Export Template to Other Machines

```bash
# From source machine
cp ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json \
   ~/Desktop/hp_custom_template.json

# Transfer to other machine (USB, email, etc.)

# On destination machine
cp ~/Desktop/hp_custom_template.json \
   ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json
```

## Installation Scripts Behavior

All installation scripts now create BOTH files:

### Shell Script (`install_hp_py_sleep_simple.sh`)
```bash
# Creates:
# 1. hp_processor_config.json (active config)
# 2. default_config_template.json (copy of active config)
```

### Python Script (`setup_hp_py_sleep.py`)
```bash
# Creates:
# 1. hp_processor_config.json (active config)
# 2. default_config_template.json (copy of active config)
```

### Standalone Script (`setup_default_config.py`)
```bash
# Creates:
# 1. hp_processor_config.json (active config)
# 2. default_config_template.json (copy of active config)
```

## Template vs Config

| File | Purpose | When Modified |
|------|---------|---------------|
| `hp_processor_config.json` | Active settings | Every time app saves settings |
| `default_config_template.json` | Template for new configs | Only when you edit it manually |

**Key Difference**: 
- Config file changes frequently (window size, trace colors, etc.)
- Template file rarely changes (only when you want new defaults)

## Verification

### Check Template Source
```bash
# Run app and check log
tail -20 ~/Library/Application\ Support/HP\ Py\ Sleep/hp_py_sleep.log | grep template

# Look for:
# "Found config template from Library folder (user-maintained)"  ← Best!
# "Found config template from bundled (PyInstaller)"             ← Fallback
```

### View Template Contents
```bash
# Pretty-print the template
cat ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json | python3 -m json.tool

# Or use jq if installed
cat ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json | jq .
```

### Test Template
```bash
# 1. Backup current config
cp ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json \
   ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json.backup

# 2. Delete active config
rm ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json

# 3. Restart app

# 4. Verify new config matches template
diff ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json \
     ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json

# 5. Restore backup if needed
mv ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json.backup \
   ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json
```

## Common Customizations

### Add Organization-Specific Event Types
```json
{
  "event_types": {
    "Session Start": "green",
    "Session End": "red",
    "Equipment Issue": "orange",
    "Calibration": "blue",
    "Break": "yellow"
  }
}
```

### Add Research-Specific State Types
```json
{
  "state_types": {
    "Baseline": "blue",
    "Task A": "green",
    "Task B": "yellow",
    "Rest": "purple",
    "Intervention": "orange"
  }
}
```

### Set Default Window Size
```json
{
  "window_size": "10 min"
}
```

### Enable Icons by Default
```json
{
  "use_icons": true
}
```

## Multi-User Environments

### Lab/Research Setting

**Option A: Shared Template**
```bash
# Place template in shared location
/Shared/HP_Py_Sleep_Templates/default_config_template.json

# Each user copies to their Library folder
cp /Shared/HP_Py_Sleep_Templates/default_config_template.json \
   ~/Library/Application\ Support/HP\ Py\ Sleep/
```

**Option B: User-Specific Templates**
```bash
# Different templates for different roles
/Shared/HP_Py_Sleep_Templates/
├── researcher_template.json
├── technician_template.json
└── admin_template.json

# Users copy appropriate template
cp /Shared/HP_Py_Sleep_Templates/researcher_template.json \
   ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json
```

## Troubleshooting

### Template Not Used
**Symptom**: App creates config but ignores custom template

**Check**:
```bash
# Verify template exists
ls -la ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json

# Check log for template source
grep "template" ~/Library/Application\ Support/HP\ Py\ Sleep/hp_py_sleep.log
```

### Template Invalid
**Symptom**: App logs JSON error

**Solution**:
```bash
# Validate JSON
python3 -m json.tool ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json

# If invalid, restore from app bundle or recreate
python3 setup_default_config.py
```

### Want Bundled Template Back
**Symptom**: Customized template but want original

**Solution**:
```bash
# Delete custom template
rm ~/Library/Application\ Support/HP\ Py\ Sleep/default_config_template.json

# App will use bundled template on next config creation
```

## Benefits of Library Folder Priority

| Benefit | Description |
|---------|-------------|
| **User Control** | Users can update templates without developer intervention |
| **Persistence** | Templates survive app updates |
| **Lab Standards** | Easy to distribute custom templates to multiple users |
| **Testing** | Developers can test different defaults without rebuilding |
| **Flexibility** | Different machines can have different defaults |
| **Fallback** | Bundled template ensures app always works |

## Summary

```
┌─────────────────────────────────────────────────────┐
│ Template Priority Order                             │
├─────────────────────────────────────────────────────┤
│ 1. ~/Library/.../default_config_template.json     │
│    ↳ USER'S CUSTOM TEMPLATE (most current)        │
│                                                     │
│ 2. App Bundle/default_config_template.json        │
│    ↳ FALLBACK (ships with app)                    │
│                                                     │
│ 3. Project Root/default_config_template.json      │
│    ↳ DEVELOPMENT ONLY                             │
└─────────────────────────────────────────────────────┘
```

The Library folder location takes priority, giving users full control while maintaining a safe fallback to the bundled template.


