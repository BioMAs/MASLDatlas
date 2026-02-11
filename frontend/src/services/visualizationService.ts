/**
 * API service for visualization operations
 */
import { apiClient } from '../lib/api';
import type { VisualizationResponse } from '../types/api';

export const visualizationService = {
  /**
   * Generate UMAP plot
   */
  async generateUMAP(
    sessionId: string,
    colorBy: string = 'CellType'
  ): Promise<VisualizationResponse> {
    const response = await apiClient.get(`/visualization/umap/${sessionId}`, {
      params: { color_by: colorBy },
    });
    return response.data;
  },

  /**
   * Generate violin plot
   */
  async generateViolin(
    sessionId: string,
    genes: string[],
    groupby: string = 'CellType'
  ): Promise<VisualizationResponse> {
    const response = await apiClient.get(`/visualization/violin/${sessionId}`, {
      params: {
        genes: genes.join(','),
        groupby,
      },
    });
    return response.data;
  },

  /**
   * Generate dot plot
   */
  async generateDotPlot(
    sessionId: string,
    genes: string[],
    groupby: string = 'CellType'
  ): Promise<VisualizationResponse> {
    const response = await apiClient.get(`/visualization/dotplot/${sessionId}`, {
      params: {
        genes: genes.join(','),
        groupby,
      },
    });
    return response.data;
  },

  /**
   * Generate correlation scatter plot
   */
  async generateCorrelationScatter(
    sessionId: string,
    gene1: string,
    gene2: string,
    correlation: number,
    pvalue: number
  ): Promise<VisualizationResponse> {
    const response = await apiClient.post(
      `/visualization/correlation-scatter/${sessionId}`,
      {
        gene1,
        gene2,
        correlation,
        pvalue,
      }
    );
    return response.data;
  },

  /**
   * Generate volcano plot
   */
  async generateVolcanoPlot(
    dgeResults: any,
    logfcThreshold: number = 0.5,
    pvalThreshold: number = 0.05
  ): Promise<VisualizationResponse> {
    const response = await apiClient.post('/visualization/volcano', {
      dge_results: dgeResults,
      logfc_threshold: logfcThreshold,
      pval_threshold: pvalThreshold,
    });
    return response.data;
  },
};
