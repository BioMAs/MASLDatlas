/**
 * Gene Correlation Component
 */
import { useState } from 'react';
import { useGeneCorrelation } from '../hooks/useAnalysis';
import Plot from 'react-plotly.js';

interface GeneCorrelationProps {
  sessionId: string;
  availableGenes?: string[];
}

export function GeneCorrelation({ sessionId, availableGenes = [] }: GeneCorrelationProps) {
  const [gene1, setGene1] = useState('');
  const [gene2, setGene2] = useState('');
  const [method, setMethod] = useState<'spearman' | 'pearson'>('spearman');
  const [removeZeros, setRemoveZeros] = useState(false);

  const { mutate: calculateCorrelation, data: corrData, isPending } = useGeneCorrelation(sessionId);

  const handleCalculate = () => {
    if (!gene1 || !gene2) return;
    
    calculateCorrelation({
      gene1,
      gene2,
      method,
      remove_zeros: removeZeros,
    });
  };

  return (
    <div className="space-y-6">
      {/* Controls */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Gene Correlation Analysis
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Gene 1 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Gene 1
            </label>
            <input
              type="text"
              value={gene1}
              onChange={(e) => setGene1(e.target.value)}
              placeholder="Enter gene name..."
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              list="gene-list-1"
            />
            <datalist id="gene-list-1">
              {availableGenes.slice(0, 100).map(g => (
                <option key={g} value={g} />
              ))}
            </datalist>
          </div>

          {/* Gene 2 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Gene 2
            </label>
            <input
              type="text"
              value={gene2}
              onChange={(e) => setGene2(e.target.value)}
              placeholder="Enter gene name..."
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              list="gene-list-2"
            />
            <datalist id="gene-list-2">
              {availableGenes.slice(0, 100).map(g => (
                <option key={g} value={g} />
              ))}
            </datalist>
          </div>

          {/* Method */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Correlation Method
            </label>
            <div className="flex space-x-4">
              <label className="flex items-center">
                <input
                  type="radio"
                  value="spearman"
                  checked={method === 'spearman'}
                  onChange={(e) => setMethod(e.target.value as any)}
                  className="mr-2"
                />
                Spearman
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  value="pearson"
                  checked={method === 'pearson'}
                  onChange={(e) => setMethod(e.target.value as any)}
                  className="mr-2"
                />
                Pearson
              </label>
            </div>
          </div>

          {/* Remove zeros */}
          <div>
            <label className="flex items-center mt-6">
              <input
                type="checkbox"
                checked={removeZeros}
                onChange={(e) => setRemoveZeros(e.target.checked)}
                className="mr-2"
              />
              <span className="text-sm text-gray-700">Remove zero counts</span>
            </label>
          </div>
        </div>

        <button
          onClick={handleCalculate}
          disabled={!gene1 || !gene2 || isPending}
          className="mt-4 w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors font-medium"
        >
          {isPending ? 'Calculating...' : 'Calculate Correlation'}
        </button>
      </div>

      {/* Results */}
      {corrData && (
        <div className="bg-white rounded-lg shadow p-6">
          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <div className="bg-blue-50 rounded-lg p-4">
              <p className="text-sm text-gray-600 mb-1">Correlation</p>
              <p className="text-2xl font-bold text-blue-600">
                {corrData.correlation.toFixed(3)}
              </p>
            </div>
            <div className="bg-purple-50 rounded-lg p-4">
              <p className="text-sm text-gray-600 mb-1">P-value</p>
              <p className="text-2xl font-bold text-purple-600">
                {corrData.pvalue.toExponential(2)}
              </p>
            </div>
            <div className="bg-green-50 rounded-lg p-4">
              <p className="text-sm text-gray-600 mb-1">Method</p>
              <p className="text-xl font-bold text-green-600 capitalize">
                {corrData.method}
              </p>
            </div>
            <div className="bg-orange-50 rounded-lg p-4">
              <p className="text-sm text-gray-600 mb-1">N Cells</p>
              <p className="text-2xl font-bold text-orange-600">
                {corrData.n_cells.toLocaleString()}
              </p>
            </div>
          </div>

          {/* Scatter Plot */}
          <Plot
            data={[
              {
                x: corrData.expr1,
                y: corrData.expr2,
                mode: 'markers',
                type: 'scatter',
                marker: {
                  size: 4,
                  color: '#3b82f6',
                  opacity: 0.5,
                },
                name: 'Expression',
              },
              // Trend line
              {
                x: corrData.expr1,
                y: corrData.expr2.map((_, i) => {
                  // Simple linear fit
                  const n = corrData.expr1.length;
                  const sumX = corrData.expr1.reduce((a, b) => a + b, 0);
                  const sumY = corrData.expr2.reduce((a, b) => a + b, 0);
                  const sumXY = corrData.expr1.reduce((sum, x, i) => sum + x * corrData.expr2[i], 0);
                  const sumX2 = corrData.expr1.reduce((sum, x) => sum + x * x, 0);
                  
                  const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
                  const intercept = (sumY - slope * sumX) / n;
                  
                  return slope * corrData.expr1[i] + intercept;
                }),
                mode: 'lines',
                type: 'scatter',
                line: {
                  color: '#ef4444',
                  width: 2,
                },
                name: 'Trend',
              },
            ]}
            layout={{
              title: { text: `${gene1} vs ${gene2} (r = ${corrData.correlation.toFixed(3)}, p = ${corrData.pvalue.toExponential(2)})` },
              xaxis: { title: `${gene1} Expression` },
              yaxis: { title: `${gene2} Expression` },
              hovermode: 'closest',
              showlegend: true,
              plot_bgcolor: '#ffffff',
              paper_bgcolor: '#ffffff',
            } as any}
            config={{
              responsive: true,
              displayModeBar: true,
              displaylogo: false,
              toImageButtonOptions: {
                format: 'png',
                filename: `correlation_${gene1}_${gene2}_${new Date().toISOString().split('T')[0]}`,
                height: 600,
                width: 800,
                scale: 2,
              },
            }}
            style={{ width: '100%', height: '500px' }}
          />
        </div>
      )}
    </div>
  );
}
