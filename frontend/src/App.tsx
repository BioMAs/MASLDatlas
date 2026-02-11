/**
 * Main App component
 */
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';
import { DatasetSelector } from './components/DatasetSelector';
import { UMAPVisualization } from './components/UMAPVisualization';
import { DatasetExploration } from './components/DatasetExploration';
import { DotPlotVisualization } from './components/DotPlotVisualization';
import { DifferentialExpression } from './components/DifferentialExpression';
import { GeneCorrelation } from './components/GeneCorrelation';
import { EnrichmentPanel } from './components/EnrichmentPanel';
import { PseudobulkAnalysis } from './components/PseudobulkAnalysis';
import { useDatasetInfo } from './hooks/useDataset';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

type AnalysisTab = 'exploration' | 'visualize' | 'dge' | 'correlation' | 'enrichment' | 'pseudobulk';

function AppContent() {
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<AnalysisTab>('exploration');
  const [selectedGene, setSelectedGene] = useState('');

  const { data: datasetInfo, isLoading: isLoadingInfo } = useDatasetInfo(sessionId);

  const tabs = [
    { id: 'exploration', label: '🔍 Exploration', icon: '🔍' },
    { id: 'visualize', label: '📊 Visualize', icon: '📊' },
    { id: 'dge', label: '🧬 Differential Expression', icon: '🧬' },
    { id: 'correlation', label: '🔗 Correlation', icon: '🔗' },
    { id: 'enrichment', label: '🎯 Enrichment', icon: '🎯' },
    { id: 'pseudobulk', label: '🔬 Pseudo-bulk', icon: '🔬' },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-white shadow-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                MASLDatlas <span className="text-blue-600">v2.0</span>
              </h1>
              <p className="text-sm text-gray-600 mt-1">
                Multi-species scRNA-seq Atlas - Modern Stack
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
                FastAPI + React
              </span>
              {sessionId && datasetInfo && (
                <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-medium">
                  {datasetInfo.n_cells.toLocaleString()} cells
                </span>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          {/* Left Sidebar - Dataset Selection */}
          <div className="lg:col-span-1 space-y-6">
            <DatasetSelector onDatasetLoaded={setSessionId} />
            
            {/* Gene Search */}
            {sessionId && (
              <div className="bg-white rounded-lg shadow p-4">
                <h3 className="text-sm font-semibold text-gray-700 mb-3">
                  🔍 Gene Search
                </h3>
                <input
                  type="text"
                  value={selectedGene}
                  onChange={(e) => setSelectedGene(e.target.value)}
                  placeholder="Enter gene name..."
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                />
                {selectedGene && (
                  <p className="text-xs text-gray-500 mt-2">
                    Viewing: <strong>{selectedGene}</strong>
                  </p>
                )}
              </div>
            )}
          </div>

          {/* Main Area - Analysis Tabs */}
          <div className="lg:col-span-3">
            {sessionId ? (
              <>
                {isLoadingInfo ? (
                  <div className="bg-white rounded-lg shadow p-12">
                    <div className="flex flex-col items-center justify-center">
                      <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600 mb-4"></div>
                      <p className="text-gray-600 text-lg font-medium">Loading dataset information...</p>
                      <p className="text-gray-400 text-sm mt-2">Please wait while we fetch the data</p>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Tabs */}
                    <div className="bg-white rounded-lg shadow">
                  <div className="border-b border-gray-200">
                    <nav className="flex -mb-px">
                      {tabs.map((tab) => (
                        <button
                          key={tab.id}
                          onClick={() => setActiveTab(tab.id as AnalysisTab)}
                          className={`
                            flex-1 py-4 px-6 text-center border-b-2 font-medium text-sm transition-colors
                            ${
                              activeTab === tab.id
                                ? 'border-blue-500 text-blue-600'
                                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                            }
                          `}
                        >
                          <span className="mr-2">{tab.icon}</span>
                          {tab.label}
                        </button>
                      ))}
                    </nav>
                  </div>

                  <div className="p-6">
                    {/* Tab Content */}
                    {activeTab === 'exploration' && (
                      <DatasetExploration sessionId={sessionId} />
                    )}
                    
                    {activeTab === 'visualize' && (
                      <div className="space-y-6">
                        <UMAPVisualization
                          sessionId={sessionId}
                          gene={selectedGene || undefined}
                        />
                        <div className="bg-white p-4 rounded-lg shadow">
                            <h4 className="font-semibold mb-2">Dot Plot</h4>
                            <p className="text-sm text-gray-500 mb-2">Enter multiple genes separated by comma in the gene search box above to see DotPlot.</p>
                            {selectedGene && selectedGene.includes(',') && (
                                <DotPlotVisualization
                                    sessionId={sessionId}
                                    genes={selectedGene.split(',').map(g => g.trim())}
                                />
                            )}
                        </div>
                      </div>
                    )}

                    {activeTab === 'dge' && datasetInfo && (
                      <DifferentialExpression
                        sessionId={sessionId}
                        cellTypes={datasetInfo.cell_types}
                      />
                    )}

                    {activeTab === 'correlation' && (
                      <GeneCorrelation
                        sessionId={sessionId}
                        availableGenes={datasetInfo?.var_keys || []}
                      />
                    )}

                    {activeTab === 'enrichment' && datasetInfo && (
                      <EnrichmentPanel 
                        sessionId={sessionId}
                        organism={datasetInfo.organism}
                      />
                    )}

                    {activeTab === 'pseudobulk' && (
                      <PseudobulkAnalysis sessionId={sessionId} />
                    )}
                  </div>
                </div>
              </div>
                )}
              </>
            ) : (
              <div className="bg-white rounded-lg shadow p-12">
                <div className="text-center text-gray-500">
                  <svg
                    className="mx-auto h-16 w-16 text-gray-400 mb-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                  <p className="text-xl font-medium mb-2">No dataset loaded</p>
                  <p className="text-sm">Select and load a dataset to begin analysis</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="mt-12 bg-white border-t border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <p className="text-center text-sm text-gray-600">
            MASLDatlas v2.0 - Powered by FastAPI, React, and Scanpy
          </p>
        </div>
      </footer>
    </div>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AppContent />
    </QueryClientProvider>
  );
}

export default App;

