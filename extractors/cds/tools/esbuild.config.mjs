import { statSync } from 'fs';
import { resolve } from 'path';

import { build as esbuildFunc } from 'esbuild';

const NODE_VERSION_TARGET = 'node18';

// Plugin to handle shell-quote module resolution
const shellQuotePlugin = {
  name: 'shell-quote-fix',
  setup(build) {
    // Handle shell-quote internal module resolution
    build.onResolve({ filter: /^\.\/quote$/ }, args => {
      if (args.importer.includes('shell-quote')) {
        return { path: resolve(args.resolveDir, 'quote.js') };
      }
    });

    build.onResolve({ filter: /^\.\/parse$/ }, args => {
      if (args.importer.includes('shell-quote')) {
        return { path: resolve(args.resolveDir, 'parse.js') };
      }
    });
  },
};

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
  // Plugin to handle shell-quote module resolution
  plugins: [shellQuotePlugin],
  // Resolve TypeScript paths
  resolveExtensions: ['.ts', '.js'],
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
