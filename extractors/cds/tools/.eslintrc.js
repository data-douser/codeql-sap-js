module.exports = {
  parser: '@typescript-eslint/parser',
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended'
  ],
  plugins: ['@typescript-eslint'],
  env: {
    node: true,
    es2018: true
  },
  ignorePatterns: [
    'index-files.js*',
    'node_modules'
  ],
  rules: {
    'no-console': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off'
  },
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: 'module'
  }
};
