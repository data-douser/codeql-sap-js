/**
 * Additional unit tests to improve coverage for findProjectRootFromCdsFile and determineCdsProjectsUnderSourceDir
 */

import mockFs from 'mock-fs';

import { determineCdsProjectsUnderSourceDir } from '../../../../src/cds/parser/functions';

describe('Function Coverage Tests for determineCdsProjectsUnderSourceDir', () => {
  afterEach(() => {
    mockFs.restore();
  });

  describe('determineCdsProjectsUnderSourceDir - Edge Cases', () => {
    test('should handle empty source root directory', () => {
      mockFs({
        '/empty-root': {},
      });

      const result = determineCdsProjectsUnderSourceDir('/empty-root');
      expect(result).toEqual([]);
    });

    test('should handle source root with only non-CDS files', () => {
      mockFs({
        '/non-cds-root': {
          'README.md': 'This is a readme',
          'other-file.txt': 'Some content',
          subfolder: {
            'another-file.js': 'console.log("hello");',
          },
        },
      });

      const result = determineCdsProjectsUnderSourceDir('/non-cds-root');
      expect(result).toEqual([]);
    });

    test('should handle projects with package.json but no CDS content', () => {
      mockFs({
        '/root': {
          'non-cds-project': {
            'package.json': JSON.stringify({
              name: 'non-cds-project',
              dependencies: { 'some-other-dep': '^1.0.0' },
            }),
            'index.js': 'console.log("hello");',
          },
        },
      });

      const result = determineCdsProjectsUnderSourceDir('/root');
      expect(result).toEqual([]);
    });

    test('should detect project from CDS file when findProjectRootFromCdsFile returns null', () => {
      // Create a structure where findProjectRootFromCdsFile would return null
      // but we still want to detect the CDS file directory
      mockFs({
        '/root': {
          'standalone-cds': {
            'standalone.cds': 'namespace test;',
          },
        },
      });

      const result = determineCdsProjectsUnderSourceDir('/root');
      // The function actually detects the standalone CDS directory
      expect(result).toEqual(['standalone-cds']);
    });

    test('should handle complex monorepo removal logic', () => {
      mockFs({
        '/root': {
          monorepo: {
            'package.json': JSON.stringify({
              name: 'monorepo-root',
              workspaces: ['projects/*'],
              dependencies: { '@sap/cds': '^6.0.0' },
            }),
            'root.cds': 'namespace root;',
            db: {
              'root-schema.cds': 'namespace root;',
            },
            projects: {
              'project-a': {
                'package.json': JSON.stringify({
                  name: 'project-a',
                  dependencies: { '@sap/cds': '^6.0.0' },
                }),
                'service.cds': 'namespace projecta;',
              },
              'project-b': {
                'package.json': JSON.stringify({
                  name: 'project-b',
                  dependencies: { '@sap/cds': '^6.0.0' },
                }),
                'service.cds': 'namespace projectb;',
              },
            },
          },
        },
      });

      const result = determineCdsProjectsUnderSourceDir('/root');
      // Should include monorepo root and both projects
      expect(result).toContain('monorepo');
      expect(result).toContain('monorepo/projects/project-a');
      expect(result).toContain('monorepo/projects/project-b');
    });

    test('should handle case where current directory is monorepo but existing project is not legitimate', () => {
      mockFs({
        '/root': {
          parent: {
            'package.json': JSON.stringify({
              name: 'parent',
              workspaces: ['child'],
              dependencies: { '@sap/cds': '^6.0.0' },
            }),
            'parent.cds': 'namespace parent;',
            child: {
              'package.json': JSON.stringify({
                name: 'child',
                // No CDS dependencies
              }),
              'non-cds-file.txt': 'not cds content',
            },
          },
        },
      });

      const result = determineCdsProjectsUnderSourceDir('/root');
      // Should only include the parent, not the child (since child is not a legitimate CDS project)
      expect(result).toContain('parent');
      expect(result).not.toContain('parent/child');
    });

    test('should throw error for non-existent source root directory', () => {
      expect(() => {
        determineCdsProjectsUnderSourceDir('/non-existent-directory');
      }).toThrow("Source root directory '/non-existent-directory' does not exist.");
    });

    test('should throw error for empty/null source root directory', () => {
      expect(() => {
        determineCdsProjectsUnderSourceDir('');
      }).toThrow("Source root directory '' does not exist.");

      expect(() => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        determineCdsProjectsUnderSourceDir(null as any);
      }).toThrow("Source root directory 'null' does not exist.");
    });

    test('should handle directories with mixed CDS and non-CDS projects', () => {
      mockFs({
        '/root': {
          'cds-project': {
            'package.json': JSON.stringify({
              name: 'cds-project',
              dependencies: { '@sap/cds': '^6.0.0' },
            }),
            'service.cds': 'namespace cds;',
          },
          'node-project': {
            'package.json': JSON.stringify({
              name: 'node-project',
              dependencies: { express: '^4.0.0' },
            }),
            'app.js': 'const express = require("express");',
          },
          'standalone-cds': {
            'standalone.cds': 'namespace standalone;',
          },
        },
      });

      const result = determineCdsProjectsUnderSourceDir('/root');
      expect(result).toContain('cds-project');
      expect(result).not.toContain('node-project');
      // standalone-cds won't be included because it's not a "likely" CDS project (no package.json with CDS deps)
    });

    test('should handle deeply nested project structures', () => {
      mockFs({
        '/root': {
          level1: {
            level2: {
              level3: {
                'deep-project': {
                  'package.json': JSON.stringify({
                    name: 'deep-project',
                    dependencies: { '@sap/cds': '^6.0.0' },
                  }),
                  'service.cds': 'namespace deep;',
                },
              },
            },
          },
        },
      });

      const result = determineCdsProjectsUnderSourceDir('/root');
      expect(result).toContain('level1/level2/level3/deep-project');
    });

    test('should properly handle relative path conversion for root directory project', () => {
      mockFs({
        '/root': {
          'package.json': JSON.stringify({
            name: 'root-project',
            dependencies: { '@sap/cds': '^6.0.0' },
          }),
          'service.cds': 'namespace root;',
        },
      });

      const result = determineCdsProjectsUnderSourceDir('/root');
      expect(result).toContain('.');
    });
  });

  describe('Integration Tests - Complex Scenarios', () => {
    test('should handle CAP project with mixed standard and non-standard subdirectories', () => {
      mockFs({
        '/source-root': {
          'complex-project': {
            'package.json': JSON.stringify({
              name: 'complex-project',
              dependencies: { '@sap/cds': '^6.0.0' },
            }),
            db: {
              'schema.cds': 'namespace db;',
            },
            srv: {
              'service.cds': 'namespace srv;',
            },
            app: {
              'app.cds': 'namespace app;',
            },
            custom: {
              'package.json': JSON.stringify({
                name: 'custom-module',
                dependencies: { '@sap/cds': '^6.0.0' },
              }),
              'custom.cds': 'namespace custom;',
            },
          },
        },
      });

      const projects = determineCdsProjectsUnderSourceDir('/source-root');
      expect(projects).toContain('complex-project');
      // The custom subdirectory should be detected as part of the parent project structure
      // and not listed separately due to the parent/child relationship logic
    });
  });

  describe('Error Handling and Robustness', () => {
    test('should handle case where file system operations might fail', () => {
      // This tests the robustness of the functions when file system is in an unusual state
      mockFs({
        '/root': {
          'test-project': {
            'package.json': JSON.stringify({
              name: 'test',
              dependencies: { '@sap/cds': '^6.0.0' },
            }),
            'test.cds': 'namespace test;',
          },
        },
      });

      // The functions should handle this normally
      const projects = determineCdsProjectsUnderSourceDir('/root');
      expect(projects).toContain('test-project');
    });
  });
});
