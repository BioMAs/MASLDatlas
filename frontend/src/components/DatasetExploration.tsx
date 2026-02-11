import { useState, useEffect } from 'react';
import { UMAPVisualization } from './UMAPVisualization';
import { useDatasetInfo } from '../hooks/useDataset';
import { useMarkerGenes } from '../hooks/useAnalysis';
import type { MarkerGeneResult } from '../types/api';
import { ChevronLeftIcon, ChevronRightIcon } from '@heroicons/react/24/outline'; // Adjust import if needed based on version

interface DatasetExplorationProps {
  sessionId: string;
}

export function DatasetExploration({ sessionId }: DatasetExplorationProps) {
  const { data: datasetInfo } = useDatasetInfo(sessionId);
  const [metadataColumn, setMetadataColumn] = useState<string>('Sample'); 
  const { mutate: computeMarkers, data: markers, isPending: isLoadingMarkers } = useMarkerGenes(sessionId);
  const [markerGroupby, setMarkerGroupby] = useState<string>('CellType');

  // Load markers when component mounts or session changes
  useEffect(() => {
    if (sessionId) {
      computeMarkers({ groupby: markerGroupby, n_genes: 100 });
    }
  }, [sessionId, markerGroupby, computeMarkers]);

  // Group markers by cluster for display if needed
  const [selectedCluster, setSelectedCluster] = useState<string>('All');
  
  const uniqueClusters = markers 
    ? Array.from(new Set(markers.map(m => m.cluster))).sort() 
    : [];

  const filteredMarkers = selectedCluster === 'All' 
    ? markers 
    : markers?.filter(m => m.cluster === selectedCluster);

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  useEffect(() => {
    setCurrentPage(1);
  }, [selectedCluster, markerGroupby]);

  const totalItems = filteredMarkers?.length || 0;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const paginatedMarkers = filteredMarkers?.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  return (
    <div className="space-y-6">
      {/* Top Row: UMAPs */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Fixed UMAP: CellType */}
        <div className="bg-white rounded-lg shadow-md p-4">
          <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b pb-2">
            Global Structure (CellType)
          </h3>
          <UMAPVisualization sessionId={sessionId} colorBy="CellType" />
        </div>

        {/* Dynamic UMAP: Metadata */}
        <div className="bg-white rounded-lg shadow-md p-4">
          <div className="flex justify-between items-center mb-4 border-b pb-2">
            <h3 className="text-lg font-semibold text-gray-800">
              Metadata Visualization
            </h3>
            <select
              value={metadataColumn}
              onChange={(e) => setMetadataColumn(e.target.value)}
              className="px-3 py-1 border border-gray-300 rounded text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {datasetInfo?.metadata_columns.map((col) => (
                <option key={col} value={col}>
                  {col}
                </option>
              ))}
            </select>
          </div>
          <UMAPVisualization sessionId={sessionId} colorBy={metadataColumn} />
        </div>
      </div>

      {/* Bottom Row: Marker Genes */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <div className="flex flex-wrap justify-between items-center mb-6 gap-4">
          <div>
            <h3 className="text-xl font-bold text-gray-900">Marker Genes</h3>
            <p className="text-sm text-gray-500">
              Top discriminative genes identifying each cluster (One-vs-Rest)
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-4">
             <div className="flex items-center space-x-2">
                <label className="text-sm font-medium text-gray-700">Filter Cluster:</label>
                <select
                  value={selectedCluster}
                  onChange={(e) => setSelectedCluster(e.target.value)}
                  className="px-3 py-1 border border-gray-300 rounded text-sm"
                >
                  <option value="All">All Clusters</option>
                  {uniqueClusters.map(c => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </select>
             </div>
             <div className="flex items-center space-x-2">
                <label className="text-sm font-medium text-gray-700">Group By:</label>
                <select 
                    value={markerGroupby}
                    onChange={(e) => setMarkerGroupby(e.target.value)}
                    className="px-3 py-1 border border-gray-300 rounded text-sm"
                >
                    <option value="CellType">CellType</option>
                    {datasetInfo?.metadata_columns.filter(c => c !== 'CellType').map(c => (
                         <option key={c} value={c}>{c}</option>
                    ))}
                </select>
             </div>
             <button
              onClick={() => computeMarkers({ groupby: markerGroupby, n_genes: 100 })}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition"
              disabled={isLoadingMarkers}
            >
              {isLoadingMarkers ? 'Computing...' : 'Refresh Markers'}
            </button>
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto min-h-[400px]">
          {isLoadingMarkers ? (
            <div className="flex justify-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            </div>
          ) : paginatedMarkers && paginatedMarkers.length > 0 ? (
            <>
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Cluster
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Gene
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Score
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Avg Log2FC
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Adj P-Value
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {paginatedMarkers.map((marker, idx) => (
                    <tr key={`${marker.cluster}-${marker.gene}-${idx}`} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {marker.cluster}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-blue-600 font-semibold">
                        {marker.gene}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {marker.score?.toFixed(2)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {marker.avg_log2FC?.toFixed(2)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {marker.p_val_adj?.toExponential(2)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Pagination Controls */}
              <div className="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6 mt-4">
                <div className="hidden sm:flex flex-1 items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-700">
                      Showing <span className="font-medium">{(currentPage - 1) * itemsPerPage + 1}</span> to <span className="font-medium">{Math.min(currentPage * itemsPerPage, totalItems)}</span> of <span className="font-medium">{totalItems}</span> results
                    </p>
                  </div>
                  
                  <div className="flex items-center gap-4">
                    <select
                        value={itemsPerPage}
                        onChange={(e) => {
                            setItemsPerPage(Number(e.target.value));
                            setCurrentPage(1);
                        }}
                        className="rounded-md border-gray-300 py-1 pl-2 pr-8 text-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500"
                    >
                        <option value={10}>10 per page</option>
                        <option value={20}>20 per page</option>
                        <option value={50}>50 per page</option>
                        <option value={100}>100 per page</option>
                    </select>
                    
                    <nav className="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
                      <button
                        onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                        disabled={currentPage === 1}
                        className="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0 disabled:opacity-50"
                      >
                        <span className="sr-only">Previous</span>
                        <ChevronLeftIcon className="h-5 w-5" aria-hidden="true" />
                      </button>
                      <button
                        onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                        disabled={currentPage === totalPages}
                        className="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0 disabled:opacity-50"
                      >
                        <span className="sr-only">Next</span>
                        <ChevronRightIcon className="h-5 w-5" aria-hidden="true" />
                      </button>
                    </nav>
                  </div>
                </div>
              </div>
            </>
          ) : (
            <div className="text-center py-12 text-gray-500">
              No marker genes found.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

