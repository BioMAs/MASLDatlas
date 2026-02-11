/**
 * Differential Expression Analysis Component
 */
import { useState } from 'react';
import { useDifferentialExpression } from '../hooks/useAnalysis';
import { AgGridReact } from 'ag-grid-react';
import 'ag-grid-community/styles/ag-grid.css';
import 'ag-grid-community/styles/ag-theme-alpine.css';

interface DifferentialExpressionProps {
  sessionId: string;
  cellTypes: string[];
}

export function DifferentialExpression({ sessionId, cellTypes }: DifferentialExpressionProps) {
  const [group1, setGroup1] = useState('');
  const [group2, setGroup2] = useState('');
  const [method, setMethod] = useState<'wilcoxon' | 't-test' | 'logreg'>('wilcoxon');
  const [minLogFC, setMinLogFC] = useState(0.5);
  const [maxPval, setMaxPval] = useState(0.05);

  const { mutate: runDGE, data: dgeData, isPending, isSuccess } = useDifferentialExpression(sessionId);

  const handleRun = () => {
    if (!group1 || !group2) return;
    
    runDGE({
      group1,
      group2,
      method,
      min_logfc: minLogFC,
      max_pval: maxPval,
    });
  };

  const columnDefs = [
    { 
      field: 'names', 
      headerName: 'Gene',
      sortable: true, 
      filter: true,
      pinned: 'left',
      width: 150,
    },
    { 
      field: 'logfoldchanges', 
      headerName: 'Log2 FC',
      sortable: true,
      filter: 'agNumberColumnFilter',
      valueFormatter: (params: any) => params.value?.toFixed(3),
      cellStyle: (params: any) => {
        if (params.value > 0) return { color: '#dc2626' };
        if (params.value < 0) return { color: '#2563eb' };
        return null;
      },
    },
    { 
      field: 'pvals', 
      headerName: 'P-value',
      sortable: true,
      filter: 'agNumberColumnFilter',
      valueFormatter: (params: any) => params.value?.toExponential(2),
    },
    { 
      field: 'pvals_adj', 
      headerName: 'Adj. P-value',
      sortable: true,
      filter: 'agNumberColumnFilter',
      valueFormatter: (params: any) => params.value?.toExponential(2),
    },
    { 
      field: 'scores', 
      headerName: 'Score',
      sortable: true,
      filter: 'agNumberColumnFilter',
      valueFormatter: (params: any) => params.value?.toFixed(3),
    },
  ];

  return (
    <div className="space-y-6">
      {/* Controls */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Differential Gene Expression Analysis
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Group 1 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Group 1
            </label>
            <select
              value={group1}
              onChange={(e) => setGroup1(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select group 1...</option>
              {cellTypes.map(ct => (
                <option key={ct} value={ct}>{ct}</option>
              ))}
            </select>
          </div>

          {/* Group 2 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Group 2
            </label>
            <select
              value={group2}
              onChange={(e) => setGroup2(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select group 2...</option>
              {cellTypes.map(ct => (
                <option key={ct} value={ct}>{ct}</option>
              ))}
            </select>
          </div>

          {/* Method */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Statistical Method
            </label>
            <select
              value={method}
              onChange={(e) => setMethod(e.target.value as any)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="wilcoxon">Wilcoxon</option>
              <option value="t-test">T-test</option>
              <option value="logreg">Logistic Regression</option>
            </select>
          </div>

          {/* Min Log FC */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Min Log2 Fold Change: {minLogFC}
            </label>
            <input
              type="range"
              min="0"
              max="2"
              step="0.1"
              value={minLogFC}
              onChange={(e) => setMinLogFC(parseFloat(e.target.value))}
              className="w-full"
            />
          </div>

          {/* Max P-value */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Max P-value: {maxPval}
            </label>
            <input
              type="range"
              min="0.001"
              max="0.1"
              step="0.001"
              value={maxPval}
              onChange={(e) => setMaxPval(parseFloat(e.target.value))}
              className="w-full"
            />
          </div>
        </div>

        <button
          onClick={handleRun}
          disabled={!group1 || !group2 || isPending}
          className="mt-4 w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors font-medium"
        >
          {isPending ? 'Running Analysis...' : 'Run Differential Expression'}
        </button>
      </div>

      {/* Results */}
      {isSuccess && dgeData && (
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-900">
              Results: {dgeData.n_genes} significant genes
            </h3>
            <button
              onClick={() => {
                const csv = [
                  ['Gene', 'Log2FC', 'P-value', 'Adj. P-value', 'Score'].join(','),
                  ...dgeData.results.map((r: any) => 
                    [r.names, r.logfoldchanges, r.pvals, r.pvals_adj, r.scores].join(',')
                  )
                ].join('\n');
                const blob = new Blob([csv], { type: 'text/csv' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `dge_${group1}_vs_${group2}_${new Date().toISOString().split('T')[0]}.csv`;
                a.click();
              }}
              className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 text-sm font-medium"
            >
              📥 Download CSV
            </button>
          </div>

          <div className="ag-theme-alpine" style={{ height: 500, width: '100%' }}>
            <AgGridReact<any>
              rowData={dgeData.results}
              columnDefs={columnDefs as any}
              pagination={true}
              paginationPageSize={20}
              defaultColDef={{
                sortable: true,
                filter: true,
                resizable: true,
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}
