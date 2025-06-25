import { writeFileSync, mkdirSync, existsSync } from 'fs';
import { join } from 'path';

import { CdsCommandAnalysis } from './command';
import { cdsExtractorLog } from '../../logging';
import { CdsProject } from '../parser/types';

/**
 * Records debug information for a single project's CDS command analysis
 */
export interface ProjectDebugInfo {
  projectDir: string;
  cdsFiles: number;
  filesToCompile: number;
  hasPackageJson: boolean;
  cacheDir: string;
  expectedCdsVersion?: string;
  actualCdsVersion?: string;
  versionCompatible: boolean;
  warnings: string[];
  commandAnalysis: CdsCommandAnalysis;
}

/**
 * Lightweight debug information recorder for debug-compiler mode.
 * This replaces the heavy performDebugCompilerAnalysis function.
 */
export class DebugRecorder {
  private debugData: {
    generatedAt: string;
    sourceRoot: string;
    totalProjects: number;
    projectsAnalyzed: ProjectDebugInfo[];
  };

  constructor(sourceRoot: string, totalProjects: number) {
    this.debugData = {
      generatedAt: new Date().toISOString(),
      sourceRoot,
      totalProjects,
      projectsAnalyzed: [],
    };
  }

  /**
   * Record debug information for a project after determineCdsCommand has been called
   */
  recordProjectInfo(
    projectDir: string,
    project: CdsProject,
    cacheDir: string | undefined,
    commandAnalysis: CdsCommandAnalysis,
  ): void {
    // Extract expected CDS version from package.json
    const expectedCdsVersion = project.packageJson
      ? (project.packageJson.dependencies?.['@sap/cds'] ??
        project.packageJson.devDependencies?.['@sap/cds'])
      : undefined;

    const warnings: string[] = [];
    let versionCompatible = true;

    // Check version compatibility
    if (expectedCdsVersion && commandAnalysis.selectedVersion) {
      const expectedMajor = parseInt(expectedCdsVersion.split('.')[0], 10);
      const actualMajor = parseInt(commandAnalysis.selectedVersion.split('.')[0], 10);
      versionCompatible = expectedMajor === actualMajor;

      if (!versionCompatible) {
        warnings.push(
          `Version mismatch: expected v${expectedCdsVersion} but found v${commandAnalysis.selectedVersion}`,
        );
      }
    }

    this.debugData.projectsAnalyzed.push({
      projectDir,
      cdsFiles: project.cdsFiles.length,
      filesToCompile: project.cdsFilesToCompile.length,
      hasPackageJson: !!project.packageJson,
      cacheDir: cacheDir ?? 'none',
      expectedCdsVersion,
      actualCdsVersion: commandAnalysis.selectedVersion,
      versionCompatible,
      warnings,
      commandAnalysis,
    });
  }

  /**
   * Write debug information to file and log summary
   */
  writeDebugFile(scriptDir: string): void {
    try {
      const debugDir = join(scriptDir, 'out', 'debug');
      if (!existsSync(debugDir)) {
        mkdirSync(debugDir, { recursive: true });
      }

      const debugFilePath = join(debugDir, 'cds-extractor.compiler.debug.json');
      writeFileSync(debugFilePath, JSON.stringify(this.debugData, null, 2));

      cdsExtractorLog('info', `Compiler debug information written to: ${debugFilePath}`);

      // Log summary
      const projectsWithWorkingCds = this.debugData.projectsAnalyzed.filter(
        p => p.commandAnalysis.selectedCommand,
      ).length;
      const projectsWithVersionMismatch = this.debugData.projectsAnalyzed.filter(
        p => !p.versionCompatible,
      ).length;

      cdsExtractorLog('info', 'Compilation analysis summary:');
      cdsExtractorLog('info', `  - Total projects: ${this.debugData.totalProjects}`);
      cdsExtractorLog('info', `  - Projects with working CDS command: ${projectsWithWorkingCds}`);
      cdsExtractorLog(
        'info',
        `  - Projects with version mismatches: ${projectsWithVersionMismatch}`,
      );
    } catch (error) {
      cdsExtractorLog('warn', `Could not write compiler debug file: ${String(error)}`);
    }
  }
}

/**
 * @deprecated Use DebugRecorder class instead
 * Legacy function kept for compatibility - will be removed
 */
export function performDebugCompilerAnalysis(): void {
  throw new Error('performDebugCompilerAnalysis is deprecated. Use DebugRecorder class instead.');
}
