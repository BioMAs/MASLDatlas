#!/bin/bash

# Script pour créer des versions échantillonnées du dataset intégré
# Ce script utilise Python directement sans environnement conda

echo "🚀 Creating optimized versions of large dataset..."
echo "============================================================"

DATASET_PATH="datasets/Integrated/Fibrotic Integrated Cross Species-002.h5ad"
OUTPUT_DIR="datasets_optimized"

# Vérifier si le dataset existe
if [ ! -f "$DATASET_PATH" ]; then
    echo "❌ Dataset not found: $DATASET_PATH"
    exit 1
fi

# Créer le répertoire de sortie
mkdir -p "$OUTPUT_DIR"

echo "📁 Output directory: $OUTPUT_DIR"
echo "📊 Original dataset: $(du -h "$DATASET_PATH" | cut -f1)"
echo ""

# Créer un script Python temporaire pour l'échantillonnage
cat > /tmp/subsample_dataset.py << 'EOF'
import sys
import numpy as np
try:
    import scanpy as sc
    import pandas as pd
except ImportError as e:
    print(f"❌ Required packages not found: {e}")
    print("💡 Please install: pip install scanpy pandas")
    sys.exit(1)

def create_subsample(input_file, output_file, n_cells, seed=42):
    print(f"📥 Loading dataset: {input_file}")
    try:
        adata = sc.read_h5ad(input_file)
        print(f"📊 Original: {adata.n_obs:,} cells × {adata.n_vars:,} genes")
        
        if adata.n_obs <= n_cells:
            print(f"⚠️ Dataset has only {adata.n_obs} cells, no subsampling needed")
            return input_file
        
        # Set random seed
        np.random.seed(seed)
        
        # Random sampling
        sample_indices = np.random.choice(adata.n_obs, size=n_cells, replace=False)
        sample_indices = np.sort(sample_indices)  # Keep order for efficiency
        
        adata_sub = adata[sample_indices].copy()
        
        print(f"🎲 Subsampled: {adata_sub.n_obs:,} cells × {adata_sub.n_vars:,} genes")
        
        # Save
        adata_sub.write(output_file, compression='gzip')
        print(f"✅ Saved: {output_file}")
        
        return output_file
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python subsample_dataset.py <input> <output> <n_cells>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] 
    n_cells = int(sys.argv[3])
    
    create_subsample(input_file, output_file, n_cells)
EOF

# Fonction pour créer un échantillon
create_subsample() {
    local n_cells=$1
    local suffix=$2
    local output_file="$OUTPUT_DIR/Fibrotic Integrated Cross Species-002_$suffix.h5ad"
    
    echo "🎲 Creating ${n_cells} cell subsample..."
    
    if python3 /tmp/subsample_dataset.py "$DATASET_PATH" "$output_file" "$n_cells"; then
        echo "📉 Size: $(du -h "$output_file" | cut -f1)"
        echo "✅ Success: $suffix version created"
    else
        echo "❌ Failed to create $suffix version"
    fi
    echo ""
}

# Créer différentes tailles d'échantillons
create_subsample 5000 "sub5k"
create_subsample 10000 "sub10k" 
create_subsample 20000 "sub20k"

# Nettoyer le script temporaire
rm -f /tmp/subsample_dataset.py

echo "============================================================"
echo "✅ Dataset optimization complete!"
echo "📁 Check the following files in $OUTPUT_DIR:"
ls -lh "$OUTPUT_DIR" 2>/dev/null || echo "❌ No files created"

echo ""
echo "💡 Usage in Shiny app:"
echo "   - Select 'Integrated' organism"
echo "   - Choose dataset size (5k, 10k, or 20k cells)"
echo "   - Click 'Load Dataset'"
