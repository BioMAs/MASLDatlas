import { useState } from 'react';
import { usePseudobulk } from '../hooks/useAnalysis';
import { useDatasetInfo } from '../hooks/useDataset';

interface PseudobulkAnalysisProps {
  sessionId: string;
}

export function PseudobulkAnalysis({ sessionId }: PseudobulkAnalysisProps) {
  const { data: info } = useDatasetInfo(sessionId);
  const { mutate: runPseudobulk, isPending, data: results } = usePseudobulk(sessionId);

  const [sampleCol, setSampleCol] = useState('Sample');
  const [conditionCol, setConditionCol] = useState('Condition');
  const [refLevel, setRefLevel] = useState('');
  const [targetLevel, setTargetLevel] = useState('');
  const [cellType, setCellType] = useState('');

  const handleRun = () => {
    runPseudobulk({
      sampleCol,
      conditionCol,
      refLevel,
      targetLevel,
      cellType: cellType || undefined
    });
  };

  return (
    <div className="space-y-6 bg-white p-4 rounded-lg shadow">
      <h3 className="text-lg font-bold">Pseudo-bulk Analysis (DESeq2)</h3>
      
      <div className="grid grid-cols-2 gap-4">
        <div>
            <label className="block text-sm font-medium text-gray-700">Sample Column</label>
            <select 
                value={sampleCol} 
                onChange={(e) => setSampleCol(e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            >
                {info?.metadata_columns.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
        </div>
        <div>
            <label className="block text-sm font-medium text-gray-700">Condition Column</label>
            <select 
                value={conditionCol} 
                onChange={(e) => setConditionCol(e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            >
                {info?.metadata_columns.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
        </div>
        <div>
            <label className="block text-sm font-medium text-gray-700">Ref Level (Control)</label>
            <input 
                type="text" 
                value={refLevel} 
                onChange={(e) => setRefLevel(e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="e.g. Healthy"
            />
        </div>
        <div>
            <label className="block text-sm font-medium text-gray-700">Target Level (Case)</label>
            <input 
                type="text" 
                value={targetLevel} 
                onChange={(e) => setTargetLevel(e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="e.g. Disease"
            />
        </div>
        <div>
            <label className="block text-sm font-medium text-gray-700">Cell Type (Optional)</label>
            <select 
                value={cellType} 
                onChange={(e) => setCellType(e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            >
                <option value="">All Cells</option>
                {info?.cell_types.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
        </div>
      </div>

      <button
        onClick={handleRun}
        disabled={isPending || !refLevel || !targetLevel}
        className="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 disabled:opacity-50"
      >
        {isPending ? 'Running DESeq2...' : 'Run Analysis'}
      </button>
      <p className="text-xs text-gray-500 mt-1 italic">
        Analysis runs on the full dataset (high precision) regardless of the visualization mode.
      </p>
      
      {results && results.results && (
        <div className="mt-4">
            <h4 className="font-semibold mb-2">Results ({results.results.length} genes)</h4>
            <div className="overflow-x-auto max-h-96">
                <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50 sticky top-0">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Gene</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Log2FC</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Padj</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                        {results.results.slice(0, 100).map((res: any) => (
                            <tr key={res.gene}>
                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{res.gene}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{typeof res.log2FoldChange === 'number' ? res.log2FoldChange.toFixed(3) : 'N/A'}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{typeof res.padj === 'number' ? res.padj.toExponential(2) : 'N/A'}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {results.results.length > 100 && <p className="text-sm text-gray-500 p-2">Showing top 100 genes</p>}
            </div>
        </div>
      )}
    </div>
  );
}
