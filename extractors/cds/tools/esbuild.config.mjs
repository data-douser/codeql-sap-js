import { statSync } from 'fs';

import { build as esbuildFunc } from 'esbuild';

const buildOptions = {
  entryPoints: ['cds-extractor.ts'],
  bundle: true,
  platform: 'node',
  target: 'node18',
  outfile: 'dist/cds-extractor.bundle.js',
  external: [
    // Node.js built-in modules
    'fs',
    'path',
    'os',
    'child_process',
    'util',
    'events',
    'stream',
    'url',
    'crypto',
    'process',
    'buffer',
    'assert',
    'module',
    'net',
    'tls',
    'http',
    'https',
    'zlib',
    'readline',
    'worker_threads',
  ],
  minify: true,
  sourcemap: true,
  format: 'cjs',
  banner: {
    js: '#!/usr/bin/env node',
  },
  logLevel: 'info',
  // Handle TypeScript files
  loader: {
    '.ts': 'ts',
  },
  // Resolve TypeScript paths
  resolveExtensions: ['.ts', '.js'],
  // Ensure proper module resolution
  mainFields: ['main', 'module'],
  conditions: ['node'],
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
