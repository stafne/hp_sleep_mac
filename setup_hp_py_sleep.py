#!/usr/bin/env python3
"""
HP Py Sleep - First Time Setup Script

This script downloads and installs the latest release of HP Py Sleep from GitHub.
After running this script, users can use the built-in auto-updater for future updates.

Usage:
    python setup_hp_py_sleep.py
"""

import os
import sys
import requests
import json
import zipfile
import tempfile
import shutil
from pathlib import Path
from datetime import datetime

# GitHub repository information
GITHUB_REPO = "stafne/hp_sleep_mac"
GITHUB_API_BASE = "https://api.github.com"

def get_latest_release():
    """Get information about the latest release from GitHub."""
    try:
        print("🔍 Checking for latest release...")
        url = f"{GITHUB_API_BASE}/repos/{GITHUB_REPO}/releases/latest"
        
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        release_data = response.json()
        
        print(f"✅ Found latest release: {release_data['tag_name']}")
        print(f"📅 Published: {release_data['published_at']}")
        
        return release_data
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error fetching release information: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing release data: {e}")
        return None

def download_release_asset(release_data, asset_name_pattern="hp_py_sleep"):
    """Download the release asset (ZIP file)."""
    try:
        # Find the asset that matches our pattern
        assets = release_data.get('assets', [])
        target_asset = None
        
        for asset in assets:
            if asset_name_pattern in asset['name'] and asset['name'].endswith('.zip'):
                target_asset = asset
                break
        
        if not target_asset:
            print(f"❌ No ZIP asset found matching pattern '{asset_name_pattern}'")
            print("Available assets:")
            for asset in assets:
                print(f"  - {asset['name']}")
            return None
        
        print(f"📥 Downloading: {target_asset['name']} ({target_asset['size']} bytes)")
        
        # Download the asset
        response = requests.get(target_asset['browser_download_url'], stream=True, timeout=300)
        response.raise_for_status()
        
        # Create temporary file
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.zip')
        
        # Download with progress
        total_size = int(target_asset['size'])
        downloaded = 0
        
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                temp_file.write(chunk)
                downloaded += len(chunk)
                
                # Show progress
                progress = (downloaded / total_size) * 100
                print(f"\r📥 Downloading: {progress:.1f}% ({downloaded:,} / {total_size:,} bytes)", end='', flush=True)
        
        print()  # New line after progress
        temp_file.close()
        
        print(f"✅ Download completed: {temp_file.name}")
        return temp_file.name
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error downloading release: {e}")
        return None
    except Exception as e:
        print(f"❌ Unexpected error during download: {e}")
        return None

def extract_and_install(zip_file_path):
    """Extract the ZIP file and install to Applications folder."""
    try:
        print("📦 Extracting application...")
        
        # Create temporary directory for extraction
        temp_dir = tempfile.mkdtemp()
        
        # Extract ZIP file
        with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
        
        # Find the .app file
        app_files = list(Path(temp_dir).rglob("*.app"))
        
        if not app_files:
            print("❌ No .app file found in the downloaded package")
            print("Contents of extracted package:")
            for item in Path(temp_dir).rglob("*"):
                print(f"  - {item}")
            return False
        
        # Use the first .app file found
        source_app = app_files[0]
        app_name = source_app.name
        
        print(f"📱 Found application: {app_name}")
        
        # Determine Applications folder
        if sys.platform == "darwin":  # macOS
            applications_dir = Path("/Applications")
        else:
            print("❌ This script is designed for macOS only")
            return False
        
        # Target path in Applications
        target_path = applications_dir / app_name
        
        # Remove existing installation if it exists
        if target_path.exists():
            print(f"🗑️  Removing existing installation: {target_path}")
            shutil.rmtree(target_path)
        
        # Copy to Applications folder
        print(f"📋 Installing to: {target_path}")
        shutil.copytree(source_app, target_path)
        
        # Clean up temporary files
        shutil.rmtree(temp_dir)
        os.unlink(zip_file_path)
        
        print(f"✅ Installation completed successfully!")
        return True
        
    except zipfile.BadZipFile:
        print("❌ Invalid ZIP file")
        return False
    except PermissionError as e:
        print(f"❌ Permission denied: {e}")
        print("💡 Try running with sudo or check your permissions")
        return False
    except Exception as e:
        print(f"❌ Error during installation: {e}")
        return False

def setup_default_config():
    """Setup default configuration file for first-time users."""
    try:
        print("⚙️  Setting up configuration...")
        
        # Get the config file path (same logic as main.py)
        home_dir = Path.home()
        config_dir = home_dir / "Library" / "Application Support" / "HP Py Sleep"
        config_file = config_dir / "hp_processor_config.json"
        
        # Create config directory if it doesn't exist
        config_dir.mkdir(parents=True, exist_ok=True)
        
        # Check if config file already exists
        if config_file.exists():
            print(f"✅ Configuration file already exists: {config_file}")
            print("ℹ️  Preserving existing configuration")
            return True
        
        # Create default configuration
        print(f"📝 Creating default configuration file...")
        
        default_config = {
            "app_name": "HP Py Sleep",
            "version": "1.0.0",
            "created_by": "setup_hp_py_sleep.py",
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
        
        with open(config_file, 'w') as f:
            json.dump(default_config, f, indent=2)
        
        print(f"✅ Created default configuration: {config_file}")
        print(f"   Default event types: {', '.join(default_config['event_types'].keys())}")
        print(f"   Default state types: {', '.join(default_config['state_types'].keys())}")
        
        # Also create the template file for future use
        template_file = config_dir / "default_config_template.json"
        if not template_file.exists():
            print(f"📝 Creating config template for future resets...")
            with open(template_file, 'w') as f:
                json.dump(default_config, f, indent=2)
            print(f"✅ Created template: {template_file}")
            print(f"ℹ️  You can edit this template to customize default settings")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to setup configuration: {e}")
        return False

def main():
    """Main setup function."""
    print("=" * 60)
    print("🚀 HP Py Sleep - First Time Setup")
    print("=" * 60)
    print()
    
    # Check if we're on macOS
    if sys.platform != "darwin":
        print("❌ This setup script is designed for macOS only.")
        print("Please visit the GitHub releases page to download manually:")
        print(f"https://github.com/{GITHUB_REPO}/releases")
        return False
    
    # Check if requests module is available
    try:
        import requests
    except ImportError:
        print("❌ The 'requests' module is required but not installed.")
        print("💡 Install it with: pip install requests")
        return False
    
    print("📋 This script will:")
    print("   1. Download the latest HP Py Sleep release from GitHub")
    print("   2. Install it to your Applications folder")
    print("   3. Set up default configuration file (if needed)")
    print("   4. Prepare the application for first-time use")
    print()
    
    # Get user confirmation
    response = input("Continue? (y/N): ").strip().lower()
    if response not in ['y', 'yes']:
        print("❌ Setup cancelled by user")
        return False
    
    print()
    
    # Step 1: Get latest release info
    release_data = get_latest_release()
    if not release_data:
        return False
    
    print()
    
    # Step 2: Download the release
    zip_file = download_release_asset(release_data)
    if not zip_file:
        return False
    
    print()
    
    # Step 3: Extract and install
    success = extract_and_install(zip_file)
    
    if success:
        print()
        
        # Step 4: Setup default configuration
        config_success = setup_default_config()
        
        if not config_success:
            print("⚠️  Configuration setup failed, but app installation succeeded")
            print("   The app will create its own config file on first launch")
        print()
        print("=" * 60)
        print("🎉 Setup Completed Successfully!")
        print("=" * 60)
        print()
        print("📱 HP Py Sleep has been installed to your Applications folder.")
        print("🔍 You can find it by:")
        print("   - Opening Finder")
        print("   - Going to Applications")
        print("   - Looking for 'HP Py Sleep'")
        print()
        print("🚀 To launch the application:")
        print("   - Double-click the app in Applications, or")
        print("   - Use Spotlight (Cmd+Space) and search for 'HP Py Sleep'")
        print()
        print("🔄 Future updates:")
        print("   - The app will automatically check for updates on startup")
        print("   - You can manually check for updates from within the app")
        print()
        print("📚 For more information, visit:")
        print(f"   https://github.com/{GITHUB_REPO}")
        print()
        
        # Ask if user wants to launch the app
        launch_response = input("🚀 Launch HP Py Sleep now? (y/N): ").strip().lower()
        if launch_response in ['y', 'yes']:
            try:
                import subprocess
                app_path = "/Applications/HP Py Sleep.app"
                if os.path.exists(app_path):
                    subprocess.Popen(["open", app_path])
                    print("✅ Launching HP Py Sleep...")
                else:
                    print("⚠️  App not found at expected location. Please launch manually from Applications.")
            except Exception as e:
                print(f"⚠️  Could not launch app automatically: {e}")
                print("Please launch manually from Applications.")
        
        return True
    else:
        print()
        print("❌ Setup failed. Please try again or download manually from:")
        print(f"https://github.com/{GITHUB_REPO}/releases")
        return False

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n❌ Setup cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)
