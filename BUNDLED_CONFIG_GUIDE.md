# Bundled Default Configuration Guide

## Overview

The HP Py Sleep app now bundles a default configuration file that is automatically installed on first launch. This ensures all users start with consistent, proper default settings for event types, state types, and other preferences.

## How It Works

### Build Time
1. **Template File**: `default_config_template.json` is created in the project root
2. **PyInstaller Spec**: The spec file includes the template in the app bundle:
   ```python
   datas = [
       ('icons', 'icons'),
       ('default_config_template.json', '.')
   ]
   ```
3. **Bundling**: PyInstaller packages the template with the compiled app

### Runtime (First Launch)
1. **Check**: App checks if config exists at `~/Library/Application Support/HP Py Sleep/hp_processor_config.json`
2. **Search**: If not found, searches for bundled template in:
   - PyInstaller `_MEIPASS` directory (most common)
   - macOS app bundle Resources directory
   - Relative to executable location
3. **Install**: Copies template to user's config location
4. **Update**: Sets current timestamp and `created_by` field
5. **Load**: App loads settings from the new config file

## Default Settings

The bundled config includes:

### Event Types (Default)
```json
{
  "Start": "green",
  "Stop": "red",
  "Error": "orange"
}
```

### State Types (Default)
```json
{
  "Recording": "blue",
  "Paused": "yellow",
  "Processing": "purple"
}
```

### Other Defaults
- Window size: 5 minutes
- Max samples: 1000
- Use icons: true
- Dark mode: false
- Autoscale: resize
- Load mode: all

## Verification

### Before Building

Verify the template file is valid:
```bash
python verify_bundled_config.py
```

This checks:
- ✅ Template exists in project root
- ✅ Valid JSON format
- ✅ Required fields present
- ✅ Event and state types defined

### After Building

Verify the template was bundled correctly:
```bash
python verify_bundled_config.py
```

This checks:
- ✅ Template found in app bundle
- ✅ Located in correct directory
- ✅ Contents are valid
- ✅ All required fields present

### Testing on Test User

1. Create test user account (or use separate Mac)
2. Install the app
3. Launch and check log for:
   ```
   No config file found - checking for bundled default...
   Found bundled config template: /path/to/template
   ✅ Installed bundled default config to: ~/Library/Application Support/HP Py Sleep/hp_processor_config.json
      Event types: Start, Stop, Error
      State types: Recording, Paused, Processing
   ```

## Customizing Default Config

To change the default settings for all new installations:

1. **Edit the template**:
   ```bash
   nano default_config_template.json
   ```

2. **Add custom event types**:
   ```json
   "event_types": {
     "Start": "green",
     "Stop": "red",
     "Error": "orange",
     "Custom Event": "purple",
     "Another Event": "cyan"
   }
   ```

3. **Add custom state types**:
   ```json
   "state_types": {
     "Recording": "blue",
     "Paused": "yellow",
     "Processing": "purple",
     "Custom State": "magenta"
   }
   ```

4. **Verify changes**:
   ```bash
   python verify_bundled_config.py
   ```

5. **Rebuild**:
   ```bash
   python release_app_complete.py
   ```

## File Locations

### Development
- **Template**: `./default_config_template.json`
- **Spec file**: `./hp_py_sleep_mac.spec`

### Compiled App Bundle
- **Template location** (most common): `.app/Contents/MacOS/_internal/default_config_template.json`
- **Alternative locations**:
  - `.app/Contents/Resources/default_config_template.json`
  - `.app/Contents/MacOS/default_config_template.json`

### User's System
- **Config file**: `~/Library/Application Support/HP Py Sleep/hp_processor_config.json`
- **Log file**: `~/Library/Application Support/HP Py Sleep/hp_py_sleep.log`

## Behavior

### First Launch (No Config)
```
[2025-10-08 14:30:00] No config file found - checking for bundled default...
[2025-10-08 14:30:00] Found bundled config template: /var/.../default_config_template.json
[2025-10-08 14:30:00] ✅ Installed bundled default config to: ~/Library/Application Support/HP Py Sleep/hp_processor_config.json
[2025-10-08 14:30:00]    Event types: Start, Stop, Error
[2025-10-08 14:30:00]    State types: Recording, Paused, Processing
```

### Subsequent Launches (Config Exists)
```
[2025-10-08 15:00:00] Loading settings from ~/Library/Application Support/HP Py Sleep/hp_processor_config.json
```

### Migration from Legacy (Config in Old Location)
```
[2025-10-08 14:30:00] Migrating config from legacy location...
[2025-10-08 14:30:00] ✓ Config migrated successfully
```

## Fallback Behavior

If bundled template is not found:
1. App logs: `No bundled config template found - app will create defaults`
2. App continues with hard-coded defaults
3. Config file is created when app first saves settings
4. Works identically to previous behavior

## Troubleshooting

### Template Not Bundled
**Symptom**: `verify_bundled_config.py` shows "not found"

**Solution**:
1. Check `default_config_template.json` exists in project root
2. Verify spec file includes template in `datas`
3. Rebuild app

### Config Not Created on First Launch
**Symptom**: No config file after launching as new user

**Solution**:
1. Check log file for error messages
2. Verify permissions on `~/Library/Application Support/`
3. Run app from Terminal to see any errors

### Wrong Default Values
**Symptom**: App shows unexpected event/state types

**Solution**:
1. Open `default_config_template.json`
2. Verify JSON is valid
3. Check event_types and state_types fields
4. Rebuild app

## Benefits

### For Developers
- ✅ Consistent defaults across all installations
- ✅ Easy to update defaults (edit template, rebuild)
- ✅ Verifiable at build time
- ✅ No separate installation scripts needed

### For Users
- ✅ Proper defaults on first launch
- ✅ No manual configuration required
- ✅ Expected event and state types ready to use
- ✅ Consistent experience across machines

### For Support
- ✅ Predictable initial state
- ✅ Easier troubleshooting (known defaults)
- ✅ Clear log messages about config installation
- ✅ Verification tools available

## Integration with Installers

The bundled config works alongside installation scripts:

### Shell Script Installer (`install_hp_py_sleep_simple.sh`)
- Still creates config if app isn't launched yet
- Bundled config takes over on first app launch
- Both methods ensure config exists

### Python Installer (`setup_hp_py_sleep.py`)
- Creates config during installation
- If skipped, bundled config handles it
- Redundant but safe approach

### Auto-Updater
- Preserves existing config
- Only bundled config is used for truly first-time users
- Updates don't overwrite user settings

## Testing Checklist

Before each release:

- [ ] Verify template exists: `ls -la default_config_template.json`
- [ ] Validate JSON: `python verify_bundled_config.py`
- [ ] Build app: `python release_app_complete.py`
- [ ] Verify bundling: `python verify_bundled_config.py`
- [ ] Test on new user account
- [ ] Check log for install message
- [ ] Verify config file created
- [ ] Confirm event/state types loaded

## Version History

- **v1.0.42+**: Bundled default config feature added
- Template included in app bundle
- Automatic installation on first launch
- Verification tools provided


