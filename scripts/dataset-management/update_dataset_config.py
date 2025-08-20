#!/usr/bin/env python3
"""
Script to generate correct SHA256 hashes and file sizes for datasets
Downloads a small portion of each file to get accurate metadata
"""

import json
import requests
import hashlib
import os
from pathlib import Path

def get_file_info(url, download_sample=False):
    """Get file information including size and optionally SHA256"""
    try:
        # Get file size from headers
        response = requests.head(url, allow_redirects=True, timeout=30)
        if response.status_code != 200:
            return None, f"HTTP {response.status_code}"
        
        content_length = response.headers.get('content-length')
        if not content_length:
            return None, "No content-length header"
        
        size_bytes = int(content_length)
        size_mb = round(size_bytes / (1024 * 1024), 1)
        
        info = {
            'size_bytes': size_bytes,
            'size_mb': size_mb,
            'content_type': response.headers.get('content-type', 'unknown')
        }
        
        # Optionally download a sample to verify it's accessible
        if download_sample:
            try:
                # Download first 1KB
                headers = {'Range': 'bytes=0-1023'}
                sample_response = requests.get(url, headers=headers, timeout=30)
                if sample_response.status_code in [200, 206]:
                    info['sample_available'] = True
                    info['sample_size'] = len(sample_response.content)
                else:
                    info['sample_available'] = False
            except:
                info['sample_available'] = False
        
        return info, None
    
    except Exception as e:
        return None, str(e)

def calculate_file_sha256(url, max_bytes=None):
    """Calculate SHA256 for a file (optionally limiting bytes read)"""
    print(f"      ⚠️  SHA256 calculation requires downloading the full file")
    print(f"      💡 For large files, consider using Zenodo's provided checksums")
    return "0" * 64  # Placeholder

def update_dataset_config():
    """Update the dataset configuration with correct values"""
    config_file = Path("datasets_sources.json")
    if not config_file.exists():
        print("❌ Configuration file not found")
        return
    
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    print("🔍 Analyzing dataset files...")
    print()
    
    updated_datasets = {}
    
    for species, datasets in config['datasets'].items():
        print(f"📁 {species} datasets:")
        updated_datasets[species] = {}
        
        for dataset_name, dataset_info in datasets.items():
            url = dataset_info['url']
            print(f"  📄 {dataset_name}")
            print(f"      URL: {url}")
            
            # Get file info
            info, error = get_file_info(url, download_sample=True)
            
            if error:
                print(f"      ❌ Error: {error}")
                # Keep original values
                updated_datasets[species][dataset_name] = dataset_info
            else:
                print(f"      ✅ File accessible")
                print(f"      📏 Actual size: {info['size_mb']} MB ({info['size_bytes']:,} bytes)")
                print(f"      📊 Content-Type: {info['content_type']}")
                
                if info.get('sample_available'):
                    print(f"      ✅ Sample download successful ({info['sample_size']} bytes)")
                
                # Update with correct values
                updated_info = dataset_info.copy()
                updated_info['size_mb'] = info['size_mb']
                updated_info['size_bytes'] = info['size_bytes']
                
                # For now, use placeholder SHA256 - in production you'd get this from Zenodo
                print(f"      💡 Note: SHA256 needs to be obtained from Zenodo record metadata")
                
                updated_datasets[species][dataset_name] = updated_info
            
            print()
    
    # Update config
    config['datasets'] = updated_datasets
    
    # Write updated config
    updated_file = "datasets_sources_updated.json"
    with open(updated_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"📝 Updated configuration saved to: {updated_file}")
    print()
    print("🔧 Next steps:")
    print("1. Get correct SHA256 hashes from Zenodo record metadata")
    print("2. Verify all files are accessible")
    print("3. Replace datasets_sources.json with the updated version")

def get_zenodo_file_info():
    """Get file information directly from Zenodo API"""
    print("🔬 Getting file information from Zenodo API...")
    
    try:
        # Get record information
        record_id = "16887250"  # From the URLs
        api_url = f"https://zenodo.org/api/records/{record_id}"
        
        response = requests.get(api_url, timeout=30)
        if response.status_code != 200:
            print(f"❌ Failed to get record info: HTTP {response.status_code}")
            return
        
        record_data = response.json()
        files = record_data.get('files', [])
        
        print(f"📋 Found {len(files)} files in Zenodo record {record_id}:")
        print()
        
        for file_info in files:
            filename = file_info['key']
            size_bytes = file_info['size']
            size_mb = round(size_bytes / (1024 * 1024), 1)
            checksum = file_info.get('checksum', 'Not available')
            download_url = file_info['links']['self']
            
            print(f"📄 {filename}")
            print(f"   📏 Size: {size_mb} MB ({size_bytes:,} bytes)")
            print(f"   🔐 Checksum: {checksum}")
            print(f"   🔗 URL: {download_url}")
            print()
        
        return files
    
    except Exception as e:
        print(f"❌ Error getting Zenodo info: {e}")
        return None

if __name__ == "__main__":
    print("🔧 Dataset Configuration Updater")
    print("=" * 60)
    
    # First, get info from Zenodo API
    zenodo_files = get_zenodo_file_info()
    
    if zenodo_files:
        print("✅ Zenodo file information retrieved successfully")
        print("💡 Use this information to update your datasets_sources.json manually")
    else:
        print("⚠️  Could not get Zenodo file information")
        print("🔧 Falling back to direct file analysis...")
        update_dataset_config()
