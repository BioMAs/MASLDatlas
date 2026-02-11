/**
 * DotPlot Visualization Component
 */
import { useDotPlotVisualization } from '../hooks/useDataset';

interface DotPlotVisualizationProps {
  sessionId: string;
  genes: string[];
  groupby?: string;
}

export function DotPlotVisualization({ sessionId, genes, groupby = 'CellType' }: DotPlotVisualizationProps) {
  
  const { data, isLoading } = useDotPlotVisualization(sessionId, genes, groupby);
  
  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96 bg-gray-50 rounded-lg">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  // Display backend-generated DotPlot
  if (data?.image) {
    return (
      <div className="bg-white rounded-lg shadow-lg p-4">
        <div className="flex flex-col items-center">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">
            Dot Plot - {genes.length} Genes
          </h3>
          <img 
            src={data.image}
            alt={`DotPlot for ${genes.join(', ')}`}
            className="max-w-full h-auto rounded-lg shadow"
          />
          <div className="mt-2 text-sm text-gray-500 overflow-x-auto max-w-full">
            Genes: {genes.join(', ')}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex items-center justify-center h-96 bg-gray-50 rounded-lg">
      <p className="text-gray-500">No DotPlot data available</p>
    </div>
  );
}
