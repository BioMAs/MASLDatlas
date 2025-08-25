#!/usr/bin/env python3
"""
Large Dataset Optimization Script for MASLDatlas
Optimizes large datasets for better Shiny performance by:
1. Creating subsampled versions
2. Pre-computing essential embeddings
3. Creating metadata-only versions
4. Implementing lazy loading strategies
"""

import scanpy as sc
import pandas as pd
import numpy as np
import argparse
from pathlib import Path
import time
import warnings
warnings.filterwarnings('ignore')

class DatasetOptimizer:
    def __init__(self, input_file, output_dir="datasets_optimized"):
        self.input_file = Path(input_file)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
    def load_dataset(self):
        """Load the dataset with memory optimization"""
        print(f"📥 Loading dataset: {self.input_file}")
        print(f"📊 File size: {self.input_file.stat().st_size / (1024**3):.2f} GB")
        
        start_time = time.time()
        adata = sc.read_h5ad(self.input_file)
        load_time = time.time() - start_time
        
        print(f"✅ Dataset loaded in {load_time:.1f} seconds")
        print(f"📈 Shape: {adata.n_obs:,} cells × {adata.n_vars:,} genes")
        print(f"🔢 Memory usage: ~{adata.X.nbytes / (1024**3):.2f} GB")
        
        return adata
    
    def create_metadata_only(self, adata, suffix="_metadata"):
        """Create a metadata-only version (no expression data)"""
        print("🗂️  Creating metadata-only version...")
        
        # Create a copy with only obs and var metadata
        adata_meta = adata.copy()
        
        # Remove expression data but keep minimal X matrix for compatibility
        adata_meta.X = None
        adata_meta.raw = None
        
        # Keep embeddings and metadata
        # adata_meta.obs is already preserved
        # adata_meta.var is already preserved
        # adata_meta.obsm and adata_meta.varm are preserved for embeddings
        
        output_file = self.output_dir / f"{self.input_file.stem}{suffix}.h5ad"
        adata_meta.write(output_file, compression='gzip')
        
        print(f"✅ Metadata-only version saved: {output_file}")
        print(f"📉 Size reduction: {self.input_file.stat().st_size / output_file.stat().st_size:.1f}x smaller")
        
        return output_file
    
    def create_subsampled_versions(self, adata):
        """Create subsampled versions of different sizes"""
        print("🎲 Creating subsampled versions...")
        
        sample_sizes = [5000, 10000, 20000, 50000]
        output_files = []
        
        for sample_size in sample_sizes:
            if sample_size >= adata.n_obs:
                print(f"⏭️  Skipping {sample_size} cells (dataset has only {adata.n_obs} cells)")
                continue
                
            print(f"🔄 Creating {sample_size} cell subsample...")
            
            # Random sampling with stratification by cell type if available
            if 'CellType' in adata.obs.columns:
                # Stratified sampling
                sc.pp.subsample(adata, n_obs=sample_size, copy=False)
            else:
                # Random sampling
                np.random.seed(42)
                sample_indices = np.random.choice(adata.n_obs, sample_size, replace=False)
                adata_sub = adata[sample_indices].copy()
            
            output_file = self.output_dir / f"{self.input_file.stem}_sub{sample_size//1000}k.h5ad"
            adata_sub.write(output_file, compression='gzip')
            output_files.append(output_file)
            
            print(f"✅ Subsample saved: {output_file}")
            print(f"📊 Shape: {adata_sub.n_obs:,} cells × {adata_sub.n_vars:,} genes")
        
        return output_files
    
    def optimize_for_shiny(self, adata):
        """Create an optimized version specifically for Shiny performance"""
        print("⚡ Creating Shiny-optimized version...")
        
        adata_opt = adata.copy()
        
        # 1. Keep only highly variable genes for faster processing
        if 'highly_variable' in adata_opt.var.columns:
            print("🧬 Filtering to highly variable genes...")
            adata_opt = adata_opt[:, adata_opt.var.highly_variable].copy()
        else:
            print("🧬 Computing highly variable genes...")
            sc.pp.highly_variable_genes(adata_opt, min_mean=0.0125, max_mean=3, min_disp=0.5)
            adata_opt = adata_opt[:, adata_opt.var.highly_variable].copy()
        
        # 2. Ensure embeddings are computed
        if 'X_umap' not in adata_opt.obsm.keys():
            print("🗺️  Computing UMAP embedding...")
            sc.pp.neighbors(adata_opt)
            sc.tl.umap(adata_opt)
        
        if 'X_pca' not in adata_opt.obsm.keys():
            print("📊 Computing PCA...")
            sc.tl.pca(adata_opt)
        
        # 3. Pre-compute cluster information if not available
        if 'leiden' not in adata_opt.obs.columns:
            print("🔗 Computing Leiden clustering...")
            sc.tl.leiden(adata_opt, resolution=0.5)
        
        # 4. Convert sparse matrices to dense for faster access (only for smaller datasets)
        if adata_opt.n_obs * adata_opt.n_vars < 50_000_000:  # ~50M elements
            print("💾 Converting to dense matrix for faster access...")
            adata_opt.X = adata_opt.X.toarray()
        
        output_file = self.output_dir / f"{self.input_file.stem}_shiny_optimized.h5ad"
        adata_opt.write(output_file, compression='gzip')
        
        print(f"✅ Shiny-optimized version saved: {output_file}")
        print(f"📊 Shape: {adata_opt.n_obs:,} cells × {adata_opt.n_vars:,} genes")
        
        return output_file
    
    def create_progressive_loading_chunks(self, adata, chunk_size=10000):
        """Create chunks for progressive loading"""
        print(f"📦 Creating chunks for progressive loading (chunk size: {chunk_size})...")
        
        chunk_dir = self.output_dir / f"{self.input_file.stem}_chunks"
        chunk_dir.mkdir(exist_ok=True)
        
        n_chunks = (adata.n_obs + chunk_size - 1) // chunk_size
        chunk_files = []
        
        for i in range(n_chunks):
            start_idx = i * chunk_size
            end_idx = min((i + 1) * chunk_size, adata.n_obs)
            
            chunk_data = adata[start_idx:end_idx].copy()
            chunk_file = chunk_dir / f"chunk_{i:03d}.h5ad"
            chunk_data.write(chunk_file, compression='gzip')
            chunk_files.append(chunk_file)
            
            print(f"📦 Chunk {i+1}/{n_chunks}: {chunk_data.n_obs} cells saved to {chunk_file}")
        
        # Create manifest file
        manifest = {
            'original_file': str(self.input_file),
            'total_cells': adata.n_obs,
            'total_genes': adata.n_vars,
            'chunk_size': chunk_size,
            'n_chunks': n_chunks,
            'chunk_files': [str(f) for f in chunk_files]
        }
        
        manifest_file = chunk_dir / "manifest.json"
        import json
        with open(manifest_file, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        print(f"✅ Progressive loading chunks created in {chunk_dir}")
        return chunk_dir
    
    def optimize_all(self):
        """Run all optimization strategies"""
        print("🚀 Starting dataset optimization...")
        print("=" * 60)
        
        # Load dataset
        adata = self.load_dataset()
        
        results = {}
        
        # 1. Metadata-only version
        try:
            results['metadata'] = self.create_metadata_only(adata)
        except Exception as e:
            print(f"❌ Metadata-only creation failed: {e}")
        
        # 2. Subsampled versions
        try:
            results['subsamples'] = self.create_subsampled_versions(adata.copy())
        except Exception as e:
            print(f"❌ Subsampling failed: {e}")
        
        # 3. Shiny-optimized version
        try:
            results['shiny_optimized'] = self.optimize_for_shiny(adata.copy())
        except Exception as e:
            print(f"❌ Shiny optimization failed: {e}")
        
        # 4. Progressive loading chunks (only for very large datasets)
        if adata.n_obs > 100000:
            try:
                results['chunks'] = self.create_progressive_loading_chunks(adata.copy())
            except Exception as e:
                print(f"❌ Chunking failed: {e}")
        
        print("=" * 60)
        print("✅ Dataset optimization complete!")
        print(f"📁 Output directory: {self.output_dir}")
        
        return results

def main():
    parser = argparse.ArgumentParser(description="Optimize large datasets for MASLDatlas")
    parser.add_argument("input_file", help="Path to input .h5ad file")
    parser.add_argument("--output-dir", default="datasets_optimized", 
                       help="Output directory for optimized files")
    parser.add_argument("--strategy", choices=["all", "metadata", "subsample", "optimize", "chunk"],
                       default="all", help="Optimization strategy to use")
    
    args = parser.parse_args()
    
    optimizer = DatasetOptimizer(args.input_file, args.output_dir)
    
    if args.strategy == "all":
        optimizer.optimize_all()
    elif args.strategy == "metadata":
        adata = optimizer.load_dataset()
        optimizer.create_metadata_only(adata)
    elif args.strategy == "subsample":
        adata = optimizer.load_dataset()
        optimizer.create_subsampled_versions(adata)
    elif args.strategy == "optimize":
        adata = optimizer.load_dataset()
        optimizer.optimize_for_shiny(adata)
    elif args.strategy == "chunk":
        adata = optimizer.load_dataset()
        optimizer.create_progressive_loading_chunks(adata)

if __name__ == "__main__":
    main()
