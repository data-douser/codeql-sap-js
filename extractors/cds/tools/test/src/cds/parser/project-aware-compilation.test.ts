import { mkdirSync, rmSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';

import { determineCdsFilesToCompile } from '../../../../src/cds/parser/functions';

describe('Project-aware compilation for CAP projects', () => {
  let tempDir: string;

  beforeEach(() => {
    // Create a temporary directory for each test
    tempDir = join(tmpdir(), `cds-test-${Date.now()}-${Math.random().toString(36).substring(7)}`);
    mkdirSync(tempDir, { recursive: true });
  });

  afterEach(() => {
    // Clean up temporary directory
    try {
      rmSync(tempDir, { recursive: true, force: true });
    } catch (error: unknown) {
      console.warn(`Warning: Could not clean up temp directory ${tempDir}: ${String(error)}`);
    }
  });

  it('should use project-level compilation for log injection test case structure', () => {
    // Create the log injection test case structure
    const projectPath = join(tempDir, 'log-injection-without-protocol-none');
    mkdirSync(projectPath, { recursive: true });
    mkdirSync(join(projectPath, 'db'), { recursive: true });
    mkdirSync(join(projectPath, 'srv'), { recursive: true });

    // Create package.json with CAP dependencies
    writeFileSync(
      join(projectPath, 'package.json'),
      JSON.stringify({
        name: 'log-injection-test',
        dependencies: {
          '@sap/cds': '^7.0.0',
        },
      }),
    );

    // Create CDS files
    writeFileSync(
      join(projectPath, 'db', 'schema.cds'),
      `namespace advanced_security.log_injection.sample_entities;

entity Entity1 {
  Attribute1 : String(100);
  Attribute2 : String(100)
}

entity Entity2 {
  Attribute3 : String(100);
  Attribute4 : String(100)
}`,
    );

    writeFileSync(
      join(projectPath, 'srv', 'service1.cds'),
      `using { advanced_security.log_injection.sample_entities as db_schema } from '../db/schema';

service Service1 @(path: '/service-1') {
  entity Service1Entity as projection on db_schema.Entity1 excluding { Attribute2 }
  
  action send1 (
    messageToPass : String
  ) returns String;
}`,
    );

    writeFileSync(
      join(projectPath, 'srv', 'service2.cds'),
      `using { advanced_security.log_injection.sample_entities as db_schema } from '../db/schema';

service Service2 @(path: '/service-2') {
  entity Service2Entity as projection on db_schema.Entity2
}`,
    );

    // Set up the project structure relative to tempDir
    const relativeProjectPath = 'log-injection-without-protocol-none';
    const project = {
      projectDir: relativeProjectPath,
      cdsFiles: [
        'log-injection-without-protocol-none/db/schema.cds',
        'log-injection-without-protocol-none/srv/service1.cds',
        'log-injection-without-protocol-none/srv/service2.cds',
      ],
      imports: new Map([
        [
          'log-injection-without-protocol-none/srv/service1.cds',
          [
            {
              resolvedPath: 'log-injection-without-protocol-none/db/schema.cds',
              path: '../db/schema',
              isRelative: true,
              isModule: false,
              statement:
                "using { advanced_security.log_injection.sample_entities as db_schema } from '../db/schema';",
            },
          ],
        ],
        [
          'log-injection-without-protocol-none/srv/service2.cds',
          [
            {
              resolvedPath: 'log-injection-without-protocol-none/db/schema.cds',
              path: '../db/schema',
              isRelative: true,
              isModule: false,
              statement:
                "using { advanced_security.log_injection.sample_entities as db_schema } from '../db/schema';",
            },
          ],
        ],
      ]),
    };

    const result = determineCdsFilesToCompile(tempDir, project);

    // The result should indicate project-level compilation
    expect(result).toEqual(['__PROJECT_LEVEL_COMPILATION__']);

    // This verifies that db/schema.cds will be compiled as part of the project
    // rather than being skipped because it's imported by other files
  });

  it('should still use individual file compilation for simple projects without CAP structure', () => {
    // Create a simple project without typical CAP structure
    const simpleProjectPath = join(tempDir, 'simple-project');
    mkdirSync(simpleProjectPath, { recursive: true });

    // Create CDS files in flat structure
    writeFileSync(
      join(simpleProjectPath, 'main.cds'),
      `using from "./model";

service MainService {
  entity Items as projection on model.Item;
}`,
    );

    writeFileSync(
      join(simpleProjectPath, 'model.cds'),
      `namespace model;

entity Item {
  id : Integer;
  name : String;
}`,
    );

    const project = {
      projectDir: 'simple-project',
      cdsFiles: ['simple-project/main.cds', 'simple-project/model.cds'],
      imports: new Map([
        [
          'simple-project/main.cds',
          [
            {
              resolvedPath: 'simple-project/model.cds',
              path: './model',
              isRelative: true,
              isModule: false,
              statement: 'using from "./model";',
            },
          ],
        ],
      ]),
    };

    const result = determineCdsFilesToCompile(tempDir, project);

    // Should use the old behavior for non-CAP projects
    expect(result).toEqual(['simple-project/main.cds']);
    expect(result).not.toContain('simple-project/model.cds');
  });
});
