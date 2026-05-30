import antfu from '@antfu/eslint-config'

export default antfu({
  typescript: true,
  formatters: true,
  vue: true,
  ignores: [
    'dist',
    'front-dist',
    '**/*.md',
    'node_modules',
    '**/migrations/**',
    '*.png',
    '*.jpg',
    '*.svg',
    '*.ttf',
    '*.otf',
    '*.md',
    '**/*.js',
    'scripts/*.js',
    '.github',
    'pnpm-workspace.yaml',
    'src/components/ui/**',
    'src/client/components/ui/**',
  ],

  stylistic: {
    indent: 2,
    quotes: 'single',
    semi: false,
  },

  rules: {
    'unicorn/filename-case': ['error', {
      case: 'kebabCase',
      ignore: ['^\\[.*\\]\\.tsx$'],
    }],
    'ts/ban-ts-comment': 'off',
    'no-console': 'off',
    'node/prefer-global/process': 'off',
    'node/prefer-global/buffer': 'off',
    'unused-imports/no-unused-vars': 'warn',
    'style/comma-dangle': ['error', 'always-multiline'],
    'style/brace-style': ['error', '1tbs', { allowSingleLine: true }],
    'style/arrow-parens': ['error', 'as-needed'],
    'ts/explicit-function-return-type': 'off',
    'ts/no-explicit-any': 'off',
    'antfu/no-top-level-await': 'off',
  },
})
