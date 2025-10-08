#!/usr/bin/env python3
"""
Setup script to create default configuration file for HP Py Sleep.
This ensures first-time users have proper default settings.
"""

import os
import json
import sys
from datetime import datetime

def create_default_config():
    """Create default configuration file if it doesn't exist"""
    
    # Get the config file path (same logic as main.py)
    home_dir = os.path.expanduser("~")
    config_dir = os.path.join(home_dir, "Library", "Application Support", "HP Py Sleep")
    config_file = os.path.join(config_dir, "hp_processor_config.json")
    
    print(f"Checking configuration file: {config_file}")
    
    # Create config directory if it doesn't exist
    if not os.path.exists(config_dir):
        print(f"Creating Application Support directory: {config_dir}")
        os.makedirs(config_dir, exist_ok=True)
        print(f"✅ Created directory: {config_dir}")
    else:
        print(f"✅ Directory exists: {config_dir}")
    
    # Check if config file already exists
    if os.path.exists(config_file):
        print(f"✅ Configuration file already exists: {config_file}")
        print("ℹ️  Preserving existing configuration")
        
        # Optionally show current event/state types
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
            
            if 'event_types' in config:
                event_types = list(config['event_types'].keys())
                print(f"   Current event types: {', '.join(event_types)}")
            
            if 'state_types' in config:
                state_types = list(config['state_types'].keys())
                print(f"   Current state types: {', '.join(state_types)}")
                
        except Exception as e:
            print(f"   Note: Could not read existing config: {e}")
        
        return True
    
    # Create default configuration
    print(f"📝 Creating default configuration file...")
    
    default_config = {
        "app_name": "HP Py Sleep",
        "version": "1.0.0",
        "created_by": "setup_default_config.py",
        "created_timestamp": datetime.now().isoformat(),
        "window_geometry": "",
        "selected_signals": [],
        "event_types": {
            "Start": "green",
            "Stop": "red",
            "Error": "orange"
        },
        "state_types": {
            "Recording": "blue",
            "Paused": "yellow",
            "Processing": "purple"
        },
        "trace_assignments": {},
        "saved_montages": [],
        "last_montage_name": None,
        "last_h5_path_var": "",
        "auto_output": False,
        "load_mode": "all",
        "max_samples": "1000",
        "autoscale": "resize",
        "anti_alias": False,
        "remove_dc": False,
        "window_size": "5 min",
        "use_icons": True,
        "dark_mode": False,
        "note": "This configuration file was created by the HP Py Sleep setup script"
    }
    
    try:
        with open(config_file, 'w') as f:
            json.dump(default_config, f, indent=2)
        
        print(f"✅ Created default configuration: {config_file}")
        print(f"   Default event types: {', '.join(default_config['event_types'].keys())}")
        print(f"   Default state types: {', '.join(default_config['state_types'].keys())}")
        
        # Also create the template file for future use
        template_file = os.path.join(config_dir, "default_config_template.json")
        if not os.path.exists(template_file):
            print(f"📝 Creating config template for future resets...")
            try:
                with open(template_file, 'w') as f:
                    json.dump(default_config, f, indent=2)
                print(f"✅ Created template: {template_file}")
                print(f"   You can edit this template to customize default settings")
            except Exception as e:
                print(f"   ⚠️  Could not create template: {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to create config file: {e}")
        return False

def main():
    """Main function"""
    print("============================================================")
    print("⚙️  HP Py Sleep - Configuration Setup")
    print("============================================================")
    print("")
    
    # Check if we're on macOS
    if sys.platform != "darwin":
        print("❌ This script is designed for macOS only.")
        print("The configuration file path assumes macOS Application Support structure.")
        return 1
    
    print("📱 Detected macOS system")
    print("")
    
    success = create_default_config()
    
    print("")
    if success:
        print("🎉 Configuration setup completed successfully!")
        print("HP Py Sleep will now use the default configuration on first launch.")
    else:
        print("❌ Configuration setup failed!")
        print("You may need to run with appropriate permissions.")
        return 1
    
    return 0

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
