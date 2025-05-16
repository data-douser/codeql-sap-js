/**
 * Result of a CDS compilation
 */
export interface CdsCompilationResult {
  success: boolean;
  message?: string;
  outputPath?: string;
}
