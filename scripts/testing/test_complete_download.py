#!/usr/bin/env python3
"""
Test script for complete dataset download functionality
Downloads the smallest dataset to verify the complete pipeline
"""

import os
import os
import sys
import tempfile
import shutil
from pathlib import Path

def test_complete_download():
    """Test downloading the smallest dataset completely"""
    print("🧪 Complete Dataset Download Test")
    print("=" * 60)
    
    # Create temporary directory for testing
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        print(f"📁 Using temporary directory: {temp_path}")
        
        try:
            # Change to script directory to find download_datasets.py
            script_dir = Path(__file__).parent.parent / "dataset-management"
            original_dir = Path.cwd()
            
            os.chdir(script_dir)
            
            # Import here to avoid path issues
            sys.path.insert(0, str(script_dir))
            from download_datasets import DatasetDownloader
            
            # Initialize downloader with temp directory
            downloader = DatasetDownloader(datasets_dir=temp_path / "datasets")
            
            # Find the smallest dataset to test with
            datasets = downloader.config['datasets']
            smallest_dataset = None
            smallest_size = float('inf')
            
            for species, species_datasets in datasets.items():
                for dataset_id, dataset_info in species_datasets.items():
                    size_mb = dataset_info.get('size_mb', 0)
                    if size_mb < smallest_size:
                        smallest_size = size_mb
                        smallest_dataset = (species, dataset_id, dataset_info)
            
            if not smallest_dataset:
                print("❌ No datasets found")
                return False
            
            species, dataset_id, dataset_info = smallest_dataset
            print(f"🎯 Testing with smallest dataset: {species}/{dataset_id} ({smallest_size} MB)")
            print()
            
            # Test download
            print("📥 Starting download test...")
            success = downloader.download_dataset(species, dataset_id, dataset_info)
            
            if success:
                # Verify file exists
                expected_path = temp_path / "datasets" / species / f"{dataset_id}.h5ad"
                if expected_path.exists():
                    file_size_mb = expected_path.stat().st_size / (1024 * 1024)
                    print(f"✅ Download successful!")
                    print(f"📄 File: {expected_path}")
                    print(f"📏 Size: {file_size_mb:.1f} MB")
                    
                    # Test checksum verification
                    md5_checksum = dataset_info.get('md5')
                    if md5_checksum:
                        print("🔍 Verifying checksum...")
                        if downloader.verify_checksum(expected_path, md5_checksum, 'md5'):
                            print("✅ Checksum verification passed!")
                        else:
                            print("❌ Checksum verification failed!")
                            return False
                    
                    return True
                else:
                    print(f"❌ File not found at expected path: {expected_path}")
                    return False
            else:
                print("❌ Download failed!")
                return False
                
        except Exception as e:
            print(f"❌ Test failed with error: {e}")
            return False

def test_download_validation():
    """Test download validation without actually downloading"""
    print("\n🔍 Dataset Download Validation Test")
    print("=" * 60)
    
    try:
        # Change to script directory to find download_datasets.py
        script_dir = Path(__file__).parent.parent / "dataset-management"
        original_dir = Path.cwd()
        
        os.chdir(script_dir)
        
        # Import here to avoid path issues
        sys.path.insert(0, str(script_dir))
        from download_datasets import DatasetDownloader
        
        downloader = DatasetDownloader()
        
        os.chdir(original_dir)
        
        # Test listing datasets
        print("📋 Listing available datasets...")
        datasets = downloader.config['datasets']
        
        total_count = 0
        total_size = 0
        
        for species, species_datasets in datasets.items():
            count = len(species_datasets)
            size = sum(d.get('size_mb', 0) for d in species_datasets.values())
            
            print(f"   {species}: {count} dataset(s), {size:.1f} MB")
            total_count += count
            total_size += size
        
        print(f"📊 Total: {total_count} datasets, {total_size:.1f} MB ({total_size/1024:.1f} GB)")
        
        # Test configuration validation
        config = downloader.config.get('config', {})
        print("\n⚙️  Configuration:")
        print(f"   Timeout: {config.get('download_timeout', 'default')}s")
        print(f"   Retry attempts: {config.get('retry_attempts', 'default')}")
        print(f"   Verify checksums: {config.get('verify_checksums', 'default')}")
        print(f"   Parallel downloads: {config.get('parallel_downloads', 'default')}")
        
        return True
        
    except Exception as e:
        print(f"❌ Validation failed: {e}")
        return False

def main():
    """Main test function"""
    if '--help' in sys.argv or '-h' in sys.argv:
        print("Complete Dataset Download Test")
        print()
        print("Usage: python test_complete_download.py [options]")
        print()
        print("Options:")
        print("  -h, --help         Show this help message")
        print("  --validation-only  Only run validation tests (no download)")
        print("  --quick-test       Download smallest dataset only")
        print()
        print("This script tests:")
        print("- Complete dataset download pipeline")
        print("- File integrity verification")
        print("- Checksum validation")
        print("- Configuration validation")
        sys.exit(0)
    
    validation_only = '--validation-only' in sys.argv
    quick_test = '--quick-test' in sys.argv or True  # Default to quick test
    
    # Always run validation
    validation_ok = test_download_validation()
    
    if validation_only:
        if validation_ok:
            print("\n🏁 Validation Results:")
            print("   ✅ All validation tests passed!")
            sys.exit(0)
        else:
            print("\n🏁 Validation Results:")
            print("   ❌ Validation tests failed!")
            sys.exit(1)
    
    # Run download test
    if quick_test:
        download_ok = test_complete_download()
    else:
        print("\n⚠️  Full download test would download all datasets (~12GB)")
        print("   Use --quick-test to download only the smallest dataset")
        download_ok = True
    
    # Final results
    print("\n🏁 Test Results:")
    if validation_ok and download_ok:
        print("   ✅ All tests passed! Dataset download system is fully functional.")
        sys.exit(0)
    else:
        print("   ❌ Some tests failed. Check the output above for details.")
        sys.exit(1)

if __name__ == "__main__":
    main()
