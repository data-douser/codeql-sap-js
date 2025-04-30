module.exports = {
  parser: '@typescript-eslint/parser',
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
    'plugin:import/errors',
    'plugin:import/warnings',
    'plugin:import/typescript',
    'plugin:prettier/recommended'
  ],
  plugins: [
    '@typescript-eslint',
    'import',
    'prettier'
  ],
  env: {
    node: true,
    es2018: true
  },
  ignorePatterns: [
    'index-files.js*',
    'node_modules',
    '*.js.map',
    '*.d.ts'
  ],
  rules: {
    // General rules
    'no-console': 'off',
    'no-duplicate-imports': 'error',
    'no-unused-vars': 'off', // Using TypeScript's version
    'no-use-before-define': 'off', // Using TypeScript's version
    'no-trailing-spaces': 'error', // Prevent trailing spaces

    // TypeScript rules
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-unused-vars': ['warn', {
      'argsIgnorePattern': '^_',
      'varsIgnorePattern': '^_'
    }],
    '@typescript-eslint/no-use-before-define': ['error', {
      'functions': false,
      'classes': true
    }],
    '@typescript-eslint/explicit-function-return-type': ['warn', {
      'allowExpressions': true,
      'allowTypedFunctionExpressions': true
    }],
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/ban-ts-comment': 'warn',
    '@typescript-eslint/prefer-nullish-coalescing': 'warn',
    '@typescript-eslint/prefer-optional-chain': 'warn',

    // Import rules
    'import/order': [
      'error',
      {
        'groups': ['builtin', 'external', 'internal', ['parent', 'sibling'], 'index'],
        'newlines-between': 'always',
        'alphabetize': { 'order': 'asc', 'caseInsensitive': true }
      }
    ],
    'import/no-duplicates': 'error',

    // Code style
    'prettier/prettier': ['error', {
      'singleQuote': true,
      'trailingComma': 'all',
      'printWidth': 100,
      'tabWidth': 2
    }]
  },
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: 'module',
    project: './tsconfig.json'
  },
  settings: {
    'import/resolver': {
      'typescript': {
        'alwaysTryTypes': true,
        'project': './tsconfig.json'
      },
      'node': {
        'extensions': ['.js', '.jsx', '.ts', '.tsx']
      }
    }
  }
}
