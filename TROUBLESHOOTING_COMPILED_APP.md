# Troubleshooting Compiled App Issues

This document addresses common issues when running the compiled HP Py Sleep app on different machines.

## Issue 1: Icons Not Loading

### Symptoms
- Icons don't appear when clicking "Use Icons" checkbox
- Buttons show text instead of icons
- Log shows "Icons directory not found"

### Root Cause
The icons directory may not be properly bundled or found by PyInstaller.

### Diagnosis Steps

1. **Check if icons are bundled:**
   ```bash
   python verify_icon_bundle.py
   ```
   This will show where icons are located in the .app bundle.

2. **Check the logs:**
   - Open the app
   - Go to "Log Viewer" tab
   - Look for lines like:
     ```
     Searching for icons directory in the following paths:
       1. /path/to/icons ✓ or ✗
     ```

3. **Verify the spec file includes icons:**
   ```python
   # In hp_py_sleep_mac.spec, line 4 should have:
   datas = [('icons', 'icons')]
   ```

### Solutions

**Solution A: Rebuild with proper icon inclusion**
```bash
# Make sure icons directory exists in project root
ls -la icons/

# Rebuild the app
python release_app_complete.py
```

**Solution B: Manual icon verification**
```bash
# After building, verify icons are in the app
find dist/hp_py_sleep_mac.app -name "icon_*.png"
```

**Solution C: Check PyInstaller version**
```bash
# Ensure PyInstaller is up to date
pip install --upgrade pyinstaller

# Rebuild
python release_app_complete.py
```

### Prevention
The app now includes comprehensive path searching that checks:
1. PyInstaller `_MEIPASS` directory (most common for bundled data)
2. macOS .app bundle Resources directory  
3. Relative to executable location
4. Development source directory (for running from Python)

---

## Issue 2: Different GUI Colors/Appearance

### Symptoms
- Background colors are different on different machines
- Windows look different than expected
- Inconsistent styling across machines

### Root Cause
macOS appearance mode (Light/Dark) affects Tkinter widgets differently based on:
- macOS version
- System Preferences > General > Appearance setting
- Individual app preferences

### Understanding the Behavior

**Tkinter on macOS:**
- Tkinter inherits macOS system appearance by default
- Light mode: Light backgrounds, dark text
- Dark mode: Dark backgrounds, light text
- Some widgets respect the system theme, others don't

**What's Affected:**
- Window backgrounds
- Button colors
- Frame backgrounds
- Label colors
- Entry field colors

**What's NOT Affected:**
- Plot canvas (matplotlib controls this)
- Custom-colored widgets (explicitly set colors)
- Log viewer (has dark mode styling built-in)

### Solutions

**Solution A: System Appearance**
The app respects the macOS system appearance setting:

1. Go to System Preferences > General
2. Select "Light" or "Dark" under Appearance
3. Restart the app

**Solution B: Force Specific Appearance (macOS 10.14+)**
You can force an app to use a specific appearance:

1. Right-click the app in Finder
2. Select "Get Info"
3. Check "Open in Low Resolution" (not what we want)

Or use command line:
```bash
# Force light mode
defaults write com.ucsf.hp_py_sleep NSRequiresAquaSystemAppearance -bool yes

# Remove forcing (use system default)
defaults delete com.ucsf.hp_py_sleep NSRequiresAquaSystemAppearance
```

**Solution C: Update Info.plist**
To force light mode for all users, add to `hp_py_sleep_mac.spec`:
```python
info_plist={
    'CFBundleShortVersionString': '1.0.42',
    'CFBundleVersion': '1.0.42',
    # ... other settings ...
    'NSRequiresAquaSystemAppearance': True,  # Force light mode
}
```

### Current Behavior
The app is designed to adapt to the system appearance:
- **Light Mode**: Standard macOS light theme
- **Dark Mode**: System dark theme for main windows, custom dark theme for log viewer

If you want consistent appearance across all machines, force light mode using Solution C.

---

## Issue 3: Both Issues Together

If you're experiencing BOTH icon loading and color issues:

### Check Build Environment
1. **Verify Python version:**
   ```bash
   python --version
   ```
   Should be Python 3.9 or later

2. **Verify PIL/Pillow:**
   ```bash
   python -c "from PIL import Image, ImageTk; print('PIL OK')"
   ```

3. **Verify Tkinter:**
   ```bash
   python -c "import tkinter; print('Tkinter OK')"
   ```

4. **Rebuild from scratch:**
   ```bash
   # Clean everything
   rm -rf build dist __pycache__ *.spec
   
   # Rebuild
   python release_app_complete.py
   ```

---

## Debugging Checklist

Before reporting an issue, please gather this information:

### System Information
```bash
# macOS version
sw_vers

# Architecture (Intel vs Apple Silicon)
uname -m

# Python version
python --version
```

### App Information
1. Open HP Py Sleep
2. Go to Log Viewer tab
3. Look for startup messages:
   - PIL availability
   - Icon loading paths
   - PyInstaller detection
   - Executable path

4. Copy the first 50 lines of the log

### Icon Loading Specific
1. Try toggling "Use Icons" checkbox
2. Check log for new messages
3. Note which buttons appear (if any)
4. Send screenshot of button appearance

---

## Contact

If issues persist after trying these solutions:

1. Run the verification script:
   ```bash
   python verify_icon_bundle.py > icon_verification.txt
   ```

2. Collect log file:
   ```bash
   cat "~/Library/Application Support/HP Py Sleep/hp_py_sleep.log" > app_log.txt
   ```

3. Report issue with:
   - System information (from checklist above)
   - icon_verification.txt
   - app_log.txt (first 100 lines)
   - Screenshots showing the issue

---

## Issue 4: Missing Default Configuration

### Symptoms
- App doesn't have expected default event types or state types
- Settings seem empty on first launch
- Config file not created automatically

### Root Cause
The bundled default config template is either missing or not being copied on first launch.

### Diagnosis Steps

1. **Verify config template is bundled:**
   ```bash
   python verify_bundled_config.py
   ```

2. **Check if config was created:**
   ```bash
   ls -la ~/Library/Application\ Support/HP\ Py\ Sleep/hp_processor_config.json
   ```

3. **Check the logs for install messages:**
   ```bash
   grep "bundled" ~/Library/Application\ Support/HP\ Py\ Sleep/hp_py_sleep.log
   ```

### Solutions

**Solution A: Rebuild with config template**
```bash
# Verify template exists
ls -la default_config_template.json

# Verify it's included in spec file
grep "default_config_template.json" hp_py_sleep_mac.spec

# Rebuild
python release_app_complete.py
```

**Solution B: Manually create config**
If the app doesn't have the bundled template, you can manually create one:
```bash
# Run the setup script
python setup_default_config.py
```

### How It Works

On first launch, the app:
1. Checks if config file exists at `~/Library/Application Support/HP Py Sleep/hp_processor_config.json`
2. If not, searches for bundled `default_config_template.json` in:
   - PyInstaller `_MEIPASS` directory
   - App bundle Resources directory
   - Relative to executable
3. Copies the template to the config location
4. Updates timestamp and loads settings

Log messages to look for:
```
No config file found - checking for bundled default...
Found bundled config template: /path/to/template
✅ Installed bundled default config to: ~/Library/Application Support/HP Py Sleep/hp_processor_config.json
   Event types: Start, Stop, Error
   State types: Recording, Paused, Processing
```

---

## Quick Fixes Summary

| Issue | Quick Fix |
|-------|-----------|
| Icons not loading | Run `python verify_icon_bundle.py` then rebuild if needed |
| Wrong colors | Check System Preferences > General > Appearance |
| Inconsistent appearance | Force light mode in Info.plist |
| Icons show on one Mac but not another | Compare macOS versions and PIL installation |
| Some buttons have icons, others don't | Check log for individual icon loading errors |
| Missing default config | Run `python verify_bundled_config.py` then rebuild if needed |
| Config not created on first launch | Check log for bundled config install messages |

---

## Prevention for Future Releases

When building new releases:

1. Always run `verify_icon_bundle.py` after building
2. Test on both Intel and Apple Silicon Macs if possible
3. Test with both Light and Dark appearance modes
4. Include icon verification in release checklist
5. Document macOS version compatibility


