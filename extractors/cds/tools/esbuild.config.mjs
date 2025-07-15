import { statSync } from 'fs';

import { build as esbuildFunc } from 'esbuild';

const NODE_VERSION_TARGET = 'node18';

const buildOptions = {
  banner: {
    js: '#!/usr/bin/env node',
  },
  bundle: true,
  conditions: ['node'],
  entryPoints: ['cds-extractor.ts'],
  external: [
    // Node.js built-in modules
    'assert',
    'buffer',
    'child_process',
    'crypto',
    'events',
    'fs',
    'http',
    'https',
    'module',
    'net',
    'os',
    'path',
    'process',
    'readline',
    'shell-quote',
    'stream',
    'tls',
    'url',
    'util',
    'worker_threads',
    'zlib',
  ],
  format: 'cjs',
  // Handle TypeScript files
  loader: {
    '.ts': 'ts',
  },
  logLevel: 'info',
  // Ensure proper module resolution
  mainFields: ['main', 'module'],
  minify: true,
  outfile: 'dist/cds-extractor.bundle.js',
  platform: 'node',
  // Resolve TypeScript paths
  resolveExtensions: ['.ts'],
  sourcemap: true,
  target: NODE_VERSION_TARGET,
};

async function build() {
  try {
    console.log('🚀 Building CDS extractor bundle...');

    const result = await esbuildFunc(buildOptions);

    if (result.errors.length > 0) {
      console.error('❌ Build errors:', result.errors);
      process.exit(1);
    }

    if (result.warnings.length > 0) {
      console.warn('⚠️  Build warnings:', result.warnings);
    }

    console.log('✅ Bundle created successfully at dist/cds-extractor.bundle.js');

    // Check bundle size
    const stats = statSync('dist/cds-extractor.bundle.js');
    // Convert bytes to MB
    const sizeInMB = stats.size / (1024 * 1024);
    console.log(`📦 Created CDS extractor JS bundle: total bundle size: ${sizeInMB.toFixed(2)} MB`);
  } catch (error) {
    console.error('❌ Build failed:', error);
    process.exit(1);
  }
}

void build();
