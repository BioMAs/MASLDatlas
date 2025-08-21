#!/usr/bin/env python3
"""
Dataset Download Manager for MASLDatlas
Downloads and verifies datasets from external sources during Docker build/deployment
"""

import json
import os
import sys
import hashlib
import requests
import time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urlparse
import argparse

class DatasetDownloader:
    def __init__(self, config_file="datasets_sources.json", datasets_dir=None):
        self.config_file = config_file
        # Use environment variable if set, otherwise use provided datasets_dir or default
        if datasets_dir is None:
            datasets_dir = os.environ.get('DATASETS_DIR', 'datasets')
        self.datasets_dir = Path(datasets_dir)
        self.config = self.load_config()
        
    def load_config(self):
        """Load dataset configuration from JSON file"""
        try:
            with open(self.config_file, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"❌ Configuration file {self.config_file} not found")
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"❌ Invalid JSON in {self.config_file}: {e}")
            sys.exit(1)
    
    def calculate_checksum(self, file_path, hash_type='md5'):
        """Calculate checksum of a file (MD5 or SHA256)"""
        if hash_type.lower() == 'md5':
            hash_obj = hashlib.md5()
        elif hash_type.lower() == 'sha256':
            hash_obj = hashlib.sha256()
        else:
            raise ValueError(f"Unsupported hash type: {hash_type}")
        
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_obj.update(chunk)
        return hash_obj.hexdigest()

    def calculate_sha256(self, file_path):
        """Calculate SHA256 checksum of a file (for backward compatibility)"""
        return self.calculate_checksum(file_path, 'sha256')

    def verify_checksum(self, file_path, expected_checksum, hash_type='md5'):
        """Verify file checksum (MD5 or SHA256)"""
        if not expected_checksum:
            print(f"⚠️  No checksum provided for {file_path}, skipping verification")
            return True
        
        print(f"🔍 Verifying {hash_type.upper()} checksum for {file_path}...")
        actual_checksum = self.calculate_checksum(file_path, hash_type)
        
        if actual_checksum == expected_checksum:
            print(f"✅ {hash_type.upper()} checksum verified for {file_path}")
            return True
        else:
            print(f"❌ {hash_type.upper()} checksum mismatch for {file_path}")
            print(f"   Expected: {expected_checksum}")
            print(f"   Actual:   {actual_checksum}")
            return False

    def download_file(self, url, file_path, expected_checksum=None, checksum_type='md5', timeout=3600):
        """Download a file with progress indicator and retry logic"""
        file_path = Path(file_path)
        file_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Check if file already exists and is valid
        if file_path.exists():
            if expected_checksum and self.verify_checksum(file_path, expected_checksum, checksum_type):
                print(f"✅ File {file_path} already exists and is valid")
                return True
            else:
                print(f"🗑️  Removing invalid file {file_path}")
                file_path.unlink()
        
        retry_attempts = self.config.get('config', {}).get('retry_attempts', 3)
        
        for attempt in range(retry_attempts):
            try:
                print(f"📥 Downloading {url} to {file_path} (attempt {attempt + 1}/{retry_attempts})")
                
                response = requests.get(url, stream=True, timeout=timeout)
                response.raise_for_status()
                
                total_size = int(response.headers.get('content-length', 0))
                downloaded_size = 0
                
                with open(file_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            downloaded_size += len(chunk)
                            
                            # Progress indicator
                            if total_size > 0:
                                progress = (downloaded_size / total_size) * 100
                                print(f"\r📊 Progress: {progress:.1f}% ({downloaded_size / 1024 / 1024:.1f} MB)", end='')
                
                print()  # New line after progress
                
                # Verify checksum if provided
                if expected_checksum and self.config.get('config', {}).get('verify_checksums', True):
                    if not self.verify_checksum(file_path, expected_checksum, checksum_type):
                        file_path.unlink()  # Remove invalid file
                        raise ValueError("Checksum verification failed")
                
                print(f"✅ Successfully downloaded {file_path}")
                return True
                
            except Exception as e:
                print(f"❌ Download attempt {attempt + 1} failed: {e}")
                if file_path.exists():
                    file_path.unlink()
                
                if attempt < retry_attempts - 1:
                    wait_time = 2 ** attempt  # Exponential backoff
                    print(f"⏳ Waiting {wait_time} seconds before retry...")
                    time.sleep(wait_time)
        
        print(f"❌ Failed to download {url} after {retry_attempts} attempts")
        return False
    
    def download_dataset(self, species, dataset_id, dataset_info):
        """Download a single dataset"""
        url = dataset_info['url']
        filename = f"{dataset_id}.h5ad"
        file_path = self.datasets_dir / species / filename
        
        # Check for MD5 or SHA256 checksum
        md5_checksum = dataset_info.get('md5')
        sha256_checksum = dataset_info.get('sha256')
        
        if md5_checksum:
            checksum = md5_checksum
            checksum_type = 'md5'
        elif sha256_checksum:
            checksum = sha256_checksum
            checksum_type = 'sha256'
        else:
            checksum = None
            checksum_type = 'md5'  # Default
        
        print(f"🧬 Processing {species}/{dataset_id}")
        return self.download_file(url, file_path, checksum, checksum_type)
    
    def download_all_datasets(self, species_filter=None, parallel=True):
        """Download all configured datasets"""
        datasets = self.config['datasets']
        download_tasks = []
        
        # Collect all download tasks
        for species, species_datasets in datasets.items():
            if species_filter and species not in species_filter:
                continue
                
            for dataset_id, dataset_info in species_datasets.items():
                download_tasks.append((species, dataset_id, dataset_info))
        
        if not download_tasks:
            print("📭 No datasets to download")
            return True
        
        print(f"📦 Found {len(download_tasks)} datasets to download")
        
        success_count = 0
        
        if parallel:
            max_workers = self.config.get('config', {}).get('parallel_downloads', 2)
            print(f"🚀 Using {max_workers} parallel downloads")
            
            with ThreadPoolExecutor(max_workers=max_workers) as executor:
                future_to_task = {
                    executor.submit(self.download_dataset, species, dataset_id, dataset_info): 
                    (species, dataset_id) for species, dataset_id, dataset_info in download_tasks
                }
                
                for future in as_completed(future_to_task):
                    species, dataset_id = future_to_task[future]
                    try:
                        if future.result():
                            success_count += 1
                    except Exception as e:
                        print(f"❌ Failed to download {species}/{dataset_id}: {e}")
        else:
            for species, dataset_id, dataset_info in download_tasks:
                if self.download_dataset(species, dataset_id, dataset_info):
                    success_count += 1
        
        print(f"\n📊 Download Summary:")
        print(f"   ✅ Successful: {success_count}/{len(download_tasks)}")
        print(f"   ❌ Failed: {len(download_tasks) - success_count}/{len(download_tasks)}")
        
        return success_count == len(download_tasks)
    
    def list_datasets(self):
        """List all configured datasets"""
        datasets = self.config['datasets']
        total_size = 0
        total_count = 0
        
        print("📋 Configured Datasets:")
        print("=" * 60)
        
        for species, species_datasets in datasets.items():
            print(f"\n🧬 {species}:")
            for dataset_id, dataset_info in species_datasets.items():
                size_mb = dataset_info.get('size_mb', 0)
                total_size += size_mb
                total_count += 1
                
                status = "✅ Downloaded" if self.is_dataset_downloaded(species, dataset_id) else "⬇️  To download"
                print(f"   • {dataset_id}: {size_mb} MB - {status}")
                print(f"     {dataset_info.get('description', 'No description')}")
        
        print(f"\n📊 Summary:")
        print(f"   Total datasets: {total_count}")
        print(f"   Total size: {total_size:.1f} MB ({total_size/1024:.1f} GB)")
    
    def is_dataset_downloaded(self, species, dataset_id):
        """Check if a dataset is already downloaded"""
        file_path = self.datasets_dir / species / f"{dataset_id}.h5ad"
        return file_path.exists()
    
    def clean_datasets(self, species_filter=None):
        """Remove all downloaded datasets"""
        datasets = self.config['datasets']
        removed_count = 0
        
        for species, species_datasets in datasets.items():
            if species_filter and species not in species_filter:
                continue
                
            species_dir = self.datasets_dir / species
            if species_dir.exists():
                for dataset_id in species_datasets.keys():
                    file_path = species_dir / f"{dataset_id}.h5ad"
                    if file_path.exists():
                        file_path.unlink()
                        removed_count += 1
                        print(f"🗑️  Removed {file_path}")
        
        print(f"📊 Removed {removed_count} dataset files")

def main():
    parser = argparse.ArgumentParser(description="Dataset Download Manager for MASLDatlas")
    parser.add_argument("action", choices=["download", "list", "clean"], 
                       help="Action to perform")
    parser.add_argument("--species", nargs="+", 
                       help="Filter by species (Human, Mouse, Zebrafish, Integrated)")
    parser.add_argument("--no-parallel", action="store_true",
                       help="Disable parallel downloads")
    parser.add_argument("--config", default="datasets_sources.json",
                       help="Configuration file path")
    parser.add_argument("--datasets-dir", default="datasets",
                       help="Datasets directory path")
    
    args = parser.parse_args()
    
    downloader = DatasetDownloader(args.config, args.datasets_dir)
    
    if args.action == "download":
        print("🚀 Starting dataset download...")
        success = downloader.download_all_datasets(
            species_filter=args.species,
            parallel=not args.no_parallel
        )
        sys.exit(0 if success else 1)
    
    elif args.action == "list":
        downloader.list_datasets()
    
    elif args.action == "clean":
        print("🧹 Cleaning datasets...")
        downloader.clean_datasets(species_filter=args.species)

if __name__ == "__main__":
    main()
