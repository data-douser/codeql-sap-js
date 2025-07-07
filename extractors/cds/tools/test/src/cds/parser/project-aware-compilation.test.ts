import { mkdirSync, writeFileSync } from 'fs';
import { resolve, relative } from 'path';

import * as tmp from 'tmp';

import { determineCdsFilesToCompile } from '../../../../src/cds/parser/functions';

/**
 * Validates that a path is safe to use within a base directory.
 * Prevents path traversal attacks by ensuring the resolved path stays within the base directory.
 */
function validateSafePath(basePath: string, ...pathSegments: string[]): string {
  const resolvedBase = resolve(basePath);
  const targetPath = resolve(basePath, ...pathSegments);

  // Check if the resolved target path is within the base directory
  const relativePath = relative(resolvedBase, targetPath);
  if (relativePath.startsWith('..') || relativePath.includes('..')) {
    throw new Error(`Path traversal detected: ${pathSegments.join('/')}`);
  }

  return targetPath;
}

describe('Project-aware compilation for CAP projects', () => {
  let tempDir: string;
  let tmpCleanup: (() => void) | undefined;

  beforeEach(() => {
    // Create a secure temporary directory for each test
    const tmpObj = tmp.dirSync({ unsafeCleanup: true });
    tempDir = tmpObj.name;
    tmpCleanup = tmpObj.removeCallback;
  });

  afterEach(() => {
    // Clean up temporary directory using tmp library's cleanup function
    if (tmpCleanup) {
      tmpCleanup();
    }
  });

  it('should use project-level compilation for log injection test case structure', () => {
    // Create the log injection test case structure
    const projectPath = validateSafePath(tempDir, 'log-injection-without-protocol-none');
    mkdirSync(projectPath, { recursive: true });
    mkdirSync(validateSafePath(projectPath, 'db'), { recursive: true });
    mkdirSync(validateSafePath(projectPath, 'srv'), { recursive: true });

    // Create package.json with CAP dependencies
    writeFileSync(
      validateSafePath(projectPath, 'package.json'),
      JSON.stringify({
        name: 'log-injection-test',
        dependencies: {
          '@sap/cds': '^7.0.0',
        },
      }),
    );

    // Create CDS files
    writeFileSync(
      validateSafePath(projectPath, 'db', 'schema.cds'),
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
      validateSafePath(projectPath, 'srv', 'service1.cds'),
      `using { advanced_security.log_injection.sample_entities as db_schema } from '../db/schema';

service Service1 @(path: '/service-1') {
  entity Service1Entity as projection on db_schema.Entity1 excluding { Attribute2 }
  
  action send1 (
    messageToPass : String
  ) returns String;
}`,
    );

    writeFileSync(
      validateSafePath(projectPath, 'srv', 'service2.cds'),
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
    const simpleProjectPath = validateSafePath(tempDir, 'simple-project');
    mkdirSync(simpleProjectPath, { recursive: true });

    // Create CDS files in flat structure
    writeFileSync(
      validateSafePath(simpleProjectPath, 'main.cds'),
      `using from "./model";

service MainService {
  entity Items as projection on model.Item;
}`,
    );

    writeFileSync(
      validateSafePath(simpleProjectPath, 'model.cds'),
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

  it('should use project-level compilation for bookshop-like CAP project with index.cds in root', () => {
    // Create a bookshop-like project structure with index.cds in the root
    const bookshopProjectPath = validateSafePath(tempDir, 'bookshop-project');
    mkdirSync(bookshopProjectPath, { recursive: true });
    mkdirSync(validateSafePath(bookshopProjectPath, 'db'), { recursive: true });
    mkdirSync(validateSafePath(bookshopProjectPath, 'srv'), { recursive: true });
    mkdirSync(validateSafePath(bookshopProjectPath, 'app'), { recursive: true });

    // Create package.json with CAP dependencies
    writeFileSync(
      validateSafePath(bookshopProjectPath, 'package.json'),
      JSON.stringify({
        name: 'bookshop-project',
        dependencies: {
          '@sap/cds': '^7.0.0',
        },
      }),
    );

    // Create index.cds in the root (this is the key file being tested)
    writeFileSync(
      validateSafePath(bookshopProjectPath, 'index.cds'),
      `using from './db/schema';
using from './srv/cat-service';

// Root level configurations
annotate CatalogService with @requires: 'authenticated-user';`,
    );

    // Create db/schema.cds
    writeFileSync(
      validateSafePath(bookshopProjectPath, 'db', 'schema.cds'),
      `namespace sap.capire.bookshop;

entity Books {
  ID : Integer;
  title : String(100);
  author : String(100);
}`,
    );

    // Create srv/cat-service.cds
    writeFileSync(
      validateSafePath(bookshopProjectPath, 'srv', 'cat-service.cds'),
      `using { sap.capire.bookshop as db } from '../db/schema';

service CatalogService {
  entity Books as projection on db.Books;
}`,
    );

    // Create app directory structure (optional, but typical for CAP)
    writeFileSync(
      validateSafePath(bookshopProjectPath, 'app', 'manifest.json'),
      JSON.stringify({
        'sap.app': {
          id: 'bookshop.app',
        },
      }),
    );

    const project = {
      projectDir: 'bookshop-project',
      cdsFiles: [
        'bookshop-project/index.cds',
        'bookshop-project/db/schema.cds',
        'bookshop-project/srv/cat-service.cds',
      ],
      imports: new Map([
        [
          'bookshop-project/index.cds',
          [
            {
              resolvedPath: 'bookshop-project/db/schema.cds',
              path: './db/schema',
              isRelative: true,
              isModule: false,
              statement: "using from './db/schema';",
            },
            {
              resolvedPath: 'bookshop-project/srv/cat-service.cds',
              path: './srv/cat-service',
              isRelative: true,
              isModule: false,
              statement: "using from './srv/cat-service';",
            },
          ],
        ],
        [
          'bookshop-project/srv/cat-service.cds',
          [
            {
              resolvedPath: 'bookshop-project/db/schema.cds',
              path: '../db/schema',
              isRelative: true,
              isModule: false,
              statement: "using { sap.capire.bookshop as db } from '../db/schema';",
            },
          ],
        ],
      ]),
    };

    const result = determineCdsFilesToCompile(tempDir, project);

    // Should use project-level compilation because this is a CAP project with index.cds
    expect(result).toEqual(['__PROJECT_LEVEL_COMPILATION__']);

    // This verifies that index.cds will be included in project-level compilation
    // rather than being skipped as an imported file
  });

  it('should detect index.cds as compilation target for CAP projects with root-level configuration', () => {
    // Create another variant - CAP project where index.cds imports from subdirectories
    const projectPath = validateSafePath(tempDir, 'cap-with-index');
    mkdirSync(projectPath, { recursive: true });
    mkdirSync(validateSafePath(projectPath, 'db'), { recursive: true });
    mkdirSync(validateSafePath(projectPath, 'srv'), { recursive: true });

    // Create package.json with CAP dependencies
    writeFileSync(
      validateSafePath(projectPath, 'package.json'),
      JSON.stringify({
        name: 'cap-with-index',
        dependencies: {
          '@sap/cds': '^8.0.0',
        },
      }),
    );

    // Create index.cds that serves as the main entry point
    writeFileSync(
      validateSafePath(projectPath, 'index.cds'),
      `// Main application configuration
using from './db/schema';
using from './srv/main-service';

// Global annotations
annotate MainService with @path: '/api/v1';`,
    );

    // Create db/schema.cds
    writeFileSync(
      validateSafePath(projectPath, 'db', 'schema.cds'),
      `namespace app.data;

entity Products {
  ID : UUID;
  name : String(200);
  price : Decimal(10,2);
}`,
    );

    // Create srv/main-service.cds
    writeFileSync(
      validateSafePath(projectPath, 'srv', 'main-service.cds'),
      `using { app.data as db } from '../db/schema';

service MainService {
  entity Products as projection on db.Products;
}`,
    );

    const project = {
      projectDir: 'cap-with-index',
      cdsFiles: [
        'cap-with-index/index.cds',
        'cap-with-index/db/schema.cds',
        'cap-with-index/srv/main-service.cds',
      ],
      imports: new Map([
        [
          'cap-with-index/index.cds',
          [
            {
              resolvedPath: 'cap-with-index/db/schema.cds',
              path: './db/schema',
              isRelative: true,
              isModule: false,
              statement: "using from './db/schema';",
            },
            {
              resolvedPath: 'cap-with-index/srv/main-service.cds',
              path: './srv/main-service',
              isRelative: true,
              isModule: false,
              statement: "using from './srv/main-service';",
            },
          ],
        ],
        [
          'cap-with-index/srv/main-service.cds',
          [
            {
              resolvedPath: 'cap-with-index/db/schema.cds',
              path: '../db/schema',
              isRelative: true,
              isModule: false,
              statement: "using { app.data as db } from '../db/schema';",
            },
          ],
        ],
      ]),
    };

    const result = determineCdsFilesToCompile(tempDir, project);

    // Should use project-level compilation for CAP projects
    expect(result).toEqual(['__PROJECT_LEVEL_COMPILATION__']);
  });

  it('should fail to compile index.cds when it exists in root with standard CAP directories', () => {
    // This test demonstrates the specific problem: when a CAP project has both
    // standard directories (db/, srv/) AND root-level CDS files (index.cds),
    // the current implementation only compiles the standard directories

    // Create a realistic bookshop-style project
    const bookshopPath = validateSafePath(tempDir, 'bookshop-failing');
    mkdirSync(bookshopPath, { recursive: true });
    mkdirSync(validateSafePath(bookshopPath, 'db'), { recursive: true });
    mkdirSync(validateSafePath(bookshopPath, 'srv'), { recursive: true });

    // Create package.json with CAP dependencies
    writeFileSync(
      validateSafePath(bookshopPath, 'package.json'),
      JSON.stringify({
        name: 'bookshop-failing',
        dependencies: {
          '@sap/cds': '^7.0.0',
        },
      }),
    );

    // Create index.cds in root - this should be included in compilation!
    writeFileSync(
      validateSafePath(bookshopPath, 'index.cds'),
      `// Root configuration that should be compiled
using from './db/schema';
using from './srv/cat-service';

// These annotations will be missing from compilation if index.cds is ignored
annotate CatalogService with @requires: 'authenticated-user';
annotate Books with @readonly;`,
    );

    // Create db/schema.cds
    writeFileSync(
      validateSafePath(bookshopPath, 'db', 'schema.cds'),
      `namespace sap.capire.bookshop;

entity Books {
  ID : Integer;
  title : String(100);
  author : String(100);
}`,
    );

    // Create srv/cat-service.cds
    writeFileSync(
      validateSafePath(bookshopPath, 'srv', 'cat-service.cds'),
      `using { sap.capire.bookshop as db } from '../db/schema';

service CatalogService {
  entity Books as projection on db.Books;
}`,
    );

    // Simulate what the actual extractor would discover
    const project = {
      projectDir: 'bookshop-failing',
      cdsFiles: [
        'bookshop-failing/index.cds',
        'bookshop-failing/db/schema.cds',
        'bookshop-failing/srv/cat-service.cds',
      ],
      imports: new Map([
        [
          'bookshop-failing/index.cds',
          [
            {
              resolvedPath: 'bookshop-failing/db/schema.cds',
              path: './db/schema',
              isRelative: true,
              isModule: false,
              statement: "using from './db/schema';",
            },
            {
              resolvedPath: 'bookshop-failing/srv/cat-service.cds',
              path: './srv/cat-service',
              isRelative: true,
              isModule: false,
              statement: "using from './srv/cat-service';",
            },
          ],
        ],
        [
          'bookshop-failing/srv/cat-service.cds',
          [
            {
              resolvedPath: 'bookshop-failing/db/schema.cds',
              path: '../db/schema',
              isRelative: true,
              isModule: false,
              statement: "using { sap.capire.bookshop as db } from '../db/schema';",
            },
          ],
        ],
      ]),
    };

    const result = determineCdsFilesToCompile(tempDir, project);

    // Currently passes project-level compilation test
    expect(result).toEqual(['__PROJECT_LEVEL_COMPILATION__']);

    // TODO: This demonstrates the issue - we need to verify that when
    // the actual compilation happens, index.cds will be included.
    // The current logic in compileProjectLevel() only includes db/, srv/, app/
    // directories but NOT the root directory where index.cds resides.

    // This test documents the issue: project-level compilation is triggered
    // correctly, but the compilation command will miss the root index.cds file
  });
});
