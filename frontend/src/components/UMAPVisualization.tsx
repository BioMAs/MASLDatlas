/**
 * UMAP Visualization Component
 */
import { useUMAPVisualization } from '../hooks/useDataset';

interface UMAPVisualizationProps {
  sessionId: string;
  colorBy?: string;
  gene?: string;
}

export function UMAPVisualization({ sessionId, colorBy = 'CellType', gene }: UMAPVisualizationProps) {
  // Use the gene name for color_by if a gene is selected, otherwise use colorBy
  const actualColorBy = gene || colorBy;
  
  const { data: umapData, isLoading } = useUMAPVisualization(sessionId, actualColorBy);
  
  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96 bg-gray-50 rounded-lg">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  // Display backend-generated UMAP
  if (umapData?.image) {
    return (
      <div className="bg-white rounded-lg shadow-lg p-4">
        <div className="flex flex-col items-center">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">
            {gene ? `UMAP - ${gene} Expression` : `UMAP - Colored by ${colorBy}`}
          </h3>
          <img 
            src={umapData.image}
            alt={gene ? `UMAP - ${gene} expression` : `UMAP colored by ${colorBy}`}
            className="max-w-full h-auto rounded-lg shadow"
          />
        </div>
      </div>
    );
  }

  return (
    <div className="flex items-center justify-center h-96 bg-gray-50 rounded-lg">
      <p className="text-gray-500">No UMAP data available</p>
    </div>
  );
}
