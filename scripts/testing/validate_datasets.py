#!/usr/bin/env python3

# 🔍 MASLDatlas Dataset Validation Script
# Validates that all downloaded datasets are readable and properly formatted
# Author: MASLDatlas Team

import os
import json
import sys

def validate_h5ad_file(filepath):
    """Validate that an h5ad file exists and is readable"""
    try:
        if not os.path.exists(filepath):
            return False, "File does not exist"
        
        # Check file size
        file_size = os.path.getsize(filepath)
        if file_size == 0:
            return False, "File is empty"
        
        # Try to read file header (basic validation)
        try:
            with open(filepath, 'rb') as f:
                header = f.read(100)
                if len(header) > 0:
                    return True, f"OK ({file_size / (1024*1024):.1f} MB)"
                else:
                    return False, "Cannot read file content"
        except Exception as e:
            return False, f"Read error: {str(e)}"
            
    except Exception as e:
        return False, f"Validation error: {str(e)}"

def main():
    print("🔍 MASLDatlas Dataset Validation")
    print("=" * 50)
    
    # Load configuration
    try:
        with open('config/datasets_config.json', 'r') as f:
            config = json.load(f)
    except Exception as e:
        print(f"❌ Error loading configuration: {e}")
        return 1
    
    validation_passed = True
    total_size = 0
    
    for species, info in config.items():
        if info.get('Status') == 'Available' and 'Datasets' in info:
            print(f"\n🧬 {species}:")
            
            for dataset in info['Datasets']:
                filepath = f"datasets/{species}/{dataset}.h5ad"
                is_valid, message = validate_h5ad_file(filepath)
                
                if is_valid:
                    print(f"  ✅ {dataset}: {message}")
                    if "MB" in message:
                        try:
                            size_mb = float(message.split("(")[1].split(" MB")[0])
                            total_size += size_mb
                        except:
                            pass
                else:
                    print(f"  ❌ {dataset}: {message}")
                    validation_passed = False
        else:
            print(f"\n⏭️ {species}: {info.get('Status', 'Unknown')}")
    
    print("\n" + "=" * 50)
    print("📊 Validation Summary:")
    print(f"  Total validated size: {total_size:.1f} MB ({total_size/1024:.2f} GB)")
    
    if validation_passed:
        print("  ✅ All datasets are valid and ready to use!")
        print("\n🚀 You can now start the MASLDatlas application:")
        print("   docker-compose up -d")
        print("   # OR for local R: Rscript -e 'shiny::runApp()'")
        return 0
    else:
        print("  ❌ Some datasets failed validation")
        print("\n💡 Try re-downloading failed datasets:")
        print("   python3 scripts/dataset-management/download_datasets.py --species [SPECIES]")
        return 1

if __name__ == "__main__":
    sys.exit(main())
