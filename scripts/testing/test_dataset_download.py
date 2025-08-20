#!/usr/bin/env python3
"""
Test script for dataset download functionality
Tests the download system without actually downloading large files
"""

import json
import os
import sys
import time
import requests
from pathlib import Path
import hashlib
from urllib.parse import urlparse

def load_config():
    """Load dataset configuration"""
    config_file = Path("config/datasets_sources.json")
    if not config_file.exists():
        # Fallback to legacy location
        config_file = Path("datasets_sources.json")
        if not config_file.exists():
            print("❌ Configuration file 'config/datasets_sources.json' not found")
            return None
    
    try:
        with open(config_file, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in configuration file: {e}")
        return None

def test_url_accessibility(url, timeout=30):
    """Test if a URL is accessible without downloading the full file"""
    try:
        # Use HEAD request to check if file exists without downloading
        response = requests.head(url, timeout=timeout, allow_redirects=True)
        
        if response.status_code == 200:
            content_length = response.headers.get('content-length')
            content_type = response.headers.get('content-type', 'unknown')
            
            size_mb = None
            if content_length:
                size_mb = int(content_length) / (1024 * 1024)
            
            return {
                'accessible': True,
                'status_code': response.status_code,
                'content_type': content_type,
                'size_mb': size_mb,
                'headers': dict(response.headers)
            }
        else:
            return {
                'accessible': False,
                'status_code': response.status_code,
                'error': f"HTTP {response.status_code}"
            }
    
    except requests.exceptions.RequestException as e:
        return {
            'accessible': False,
            'error': str(e)
        }

def test_partial_download(url, bytes_to_download=1024):
    """Test downloading first few bytes to verify file integrity"""
    try:
        headers = {'Range': f'bytes=0-{bytes_to_download-1}'}
        response = requests.get(url, headers=headers, timeout=30)
        
        if response.status_code in [200, 206]:  # 206 for partial content
            return {
                'success': True,
                'bytes_downloaded': len(response.content),
                'content_preview': response.content[:100].hex()  # First 100 bytes as hex
            }
        else:
            return {
                'success': False,
                'status_code': response.status_code
            }
    
    except requests.exceptions.RequestException as e:
        return {
            'success': False,
            'error': str(e)
        }

def validate_hash_format(hash_value, hash_type):
    """Validate hash format (MD5 or SHA256)"""
    if not hash_value:
        return False, f"{hash_type} hash is empty"
    
    expected_length = 32 if hash_type.lower() == 'md5' else 64
    
    if len(hash_value) != expected_length:
        return False, f"{hash_type} hash should be {expected_length} characters, got {len(hash_value)}"
    
    try:
        int(hash_value, 16)
        return True, f"Valid {hash_type} format"
    except ValueError:
        return False, f"{hash_type} hash contains invalid characters"

def test_datasets(config, test_download=False):
    """Test all datasets in configuration"""
    if not config or 'datasets' not in config:
        print("❌ No datasets found in configuration")
        return False
    
    total_datasets = 0
    accessible_datasets = 0
    total_size_mb = 0
    
    print("🔍 Testing dataset accessibility...\n")
    
    for species, datasets in config['datasets'].items():
        print(f"📁 {species} datasets:")
        
        for dataset_name, dataset_info in datasets.items():
            total_datasets += 1
            url = dataset_info.get('url')
            expected_md5 = dataset_info.get('md5')
            expected_sha256 = dataset_info.get('sha256')  # For backward compatibility
            expected_size_mb = dataset_info.get('size_mb', 0)
            size_bytes = dataset_info.get('size_bytes')
            description = dataset_info.get('description', 'No description')
            
            print(f"  📄 {dataset_name}")
            print(f"      Description: {description}")
            print(f"      URL: {url}")
            print(f"      Expected size: {expected_size_mb} MB")
            if size_bytes:
                print(f"      Expected bytes: {size_bytes:,}")
            
            # Validate hash format (prefer MD5, fallback to SHA256)
            if expected_md5:
                hash_valid, hash_msg = validate_hash_format(expected_md5, 'MD5')
                print(f"      ✅ MD5 format: {hash_msg}" if hash_valid else f"      ❌ MD5 format: {hash_msg}")
            elif expected_sha256:
                hash_valid, hash_msg = validate_hash_format(expected_sha256, 'SHA256')
                print(f"      ✅ SHA256 format: {hash_msg}" if hash_valid else f"      ❌ SHA256 format: {hash_msg}")
            else:
                print(f"      ⚠️  No checksum provided")
            
            # Test URL accessibility
            print(f"      🔗 Testing URL accessibility...")
            url_test = test_url_accessibility(url)
            
            if url_test['accessible']:
                accessible_datasets += 1
                actual_size_mb = url_test.get('size_mb')
                content_type = url_test.get('content_type')
                
                print(f"      ✅ URL accessible (HTTP {url_test['status_code']})")
                print(f"      📊 Content-Type: {content_type}")
                
                if actual_size_mb:
                    print(f"      📏 Actual size: {actual_size_mb:.1f} MB")
                    size_diff = abs(actual_size_mb - expected_size_mb)
                    if size_diff > 10:  # Allow 10MB tolerance
                        print(f"      ⚠️  Size mismatch: expected {expected_size_mb} MB, got {actual_size_mb:.1f} MB")
                    else:
                        print(f"      ✅ Size matches expected value")
                
                total_size_mb += expected_size_mb
                
                # Test partial download if requested
                if test_download:
                    print(f"      📥 Testing partial download...")
                    partial_test = test_partial_download(url)
                    if partial_test['success']:
                        print(f"      ✅ Partial download successful ({partial_test['bytes_downloaded']} bytes)")
                    else:
                        print(f"      ❌ Partial download failed: {partial_test.get('error', 'Unknown error')}")
            
            else:
                print(f"      ❌ URL not accessible: {url_test.get('error', 'Unknown error')}")
            
            print()
    
    # Summary
    print("=" * 60)
    print(f"📊 Summary:")
    print(f"   Total datasets: {total_datasets}")
    print(f"   Accessible datasets: {accessible_datasets}")
    print(f"   Success rate: {(accessible_datasets/total_datasets*100):.1f}%")
    print(f"   Total data size: {total_size_mb:,.0f} MB ({total_size_mb/1024:.1f} GB)")
    print()
    
    return accessible_datasets == total_datasets

def test_zenodo_api():
    """Test Zenodo API accessibility"""
    print("🔬 Testing Zenodo API...")
    try:
        # Extract record ID from one of the URLs
        config = load_config()
        if not config:
            return False
            
        # Find a Zenodo URL to extract record ID
        zenodo_record_id = None
        for species, datasets in config['datasets'].items():
            for dataset_name, dataset_info in datasets.items():
                url = dataset_info.get('url', '')
                if 'zenodo.org/record/' in url:
                    # Extract record ID from URL like https://zenodo.org/record/16887250/files/...
                    parts = url.split('/record/')
                    if len(parts) > 1:
                        record_part = parts[1].split('/')[0]
                        zenodo_record_id = record_part
                        break
            if zenodo_record_id:
                break
        
        if zenodo_record_id:
            api_url = f"https://zenodo.org/api/records/{zenodo_record_id}"
            response = requests.get(api_url, timeout=30)
            
            if response.status_code == 200:
                record_data = response.json()
                print(f"   ✅ Zenodo API accessible")
                print(f"   📋 Record ID: {zenodo_record_id}")
                print(f"   📅 Created: {record_data.get('created', 'Unknown')}")
                print(f"   📝 Title: {record_data.get('metadata', {}).get('title', 'Unknown')}")
                print(f"   👥 Creators: {len(record_data.get('metadata', {}).get('creators', []))} author(s)")
                return True
            else:
                print(f"   ❌ Zenodo API returned HTTP {response.status_code}")
                return False
        else:
            print(f"   ⚠️  No Zenodo URLs found to test API")
            return True
            
    except Exception as e:
        print(f"   ❌ Zenodo API test failed: {e}")
        return False

def main():
    """Main test function"""
    print("🧪 Dataset Download Test Suite")
    print("=" * 60)
    
    # Load configuration
    print("📋 Loading configuration...")
    config = load_config()
    if not config:
        sys.exit(1)
    
    config_settings = config.get('config', {})
    print(f"   ✅ Configuration loaded")
    print(f"   ⏱️  Download timeout: {config_settings.get('download_timeout', 'default')}s")
    print(f"   🔄 Retry attempts: {config_settings.get('retry_attempts', 'default')}")
    print(f"   🔍 Verify checksums: {config_settings.get('verify_checksums', 'default')}")
    print(f"   ⚡ Parallel downloads: {config_settings.get('parallel_downloads', 'default')}")
    print()
    
    # Test Zenodo API
    zenodo_ok = test_zenodo_api()
    print()
    
    # Test dataset accessibility
    test_partial = '--download-test' in sys.argv or '-d' in sys.argv
    if test_partial:
        print("🔬 Including partial download tests...")
    
    datasets_ok = test_datasets(config, test_download=test_partial)
    
    # Final result
    print("🏁 Test Results:")
    if zenodo_ok and datasets_ok:
        print("   ✅ All tests passed! Dataset download system is ready.")
        sys.exit(0)
    else:
        print("   ❌ Some tests failed. Check the output above for details.")
        sys.exit(1)

if __name__ == "__main__":
    if '--help' in sys.argv or '-h' in sys.argv:
        print("Dataset Download Test Suite")
        print()
        print("Usage: python test_dataset_download.py [options]")
        print()
        print("Options:")
        print("  -h, --help         Show this help message")
        print("  -d, --download-test Include partial download tests")
        print()
        print("This script tests:")
        print("- Configuration file validity")
        print("- URL accessibility for all datasets")
        print("- SHA256 hash format validation")
        print("- File size verification")
        print("- Zenodo API accessibility")
        print("- Optional: Partial download tests")
        sys.exit(0)
    
    main()
