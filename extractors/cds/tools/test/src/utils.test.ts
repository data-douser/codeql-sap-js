import { resolve } from 'path';

import { getArg, validateArguments } from '../../src/utils';

describe('utils', () => {
  describe('getArg', () => {
    it('should return the resolved argument value at specified index', () => {
      const args = ['node', 'script.js', '/path/to/argument'];
      const result = getArg(args, 2);
      expect(result).toBe(resolve('/path/to/argument'));
    });

    it('should return the default value when index is out of bounds', () => {
      const args = ['node', 'script.js'];
      const result = getArg(args, 2, 'default');
      expect(result).toBe('default');
    });

    it('should return an empty string if index is out of bounds and no default value is provided', () => {
      const args = ['node', 'script.js'];
      const result = getArg(args, 2);
      expect(result).toBe('');
    });
  });

  describe('validateArguments', () => {
    const originalConsoleWarn = console.warn;

    beforeEach(() => {
      // Mock console.warn to avoid polluting test output
      console.warn = jest.fn();
    });

    afterEach(() => {
      console.warn = originalConsoleWarn;
    });

    it('should return true when argument count matches required count', () => {
      const args = ['node', 'index-files.js', 'response-file', 'source-root'];
      const result = validateArguments(args, 4);
      expect(result).toBe(true);
      expect(console.warn).not.toHaveBeenCalled();
    });

    it('should return false and print warning when argument count does not match required count', () => {
      const args = ['node', 'index-files.js', 'response-file'];
      const result = validateArguments(args, 4);
      expect(result).toBe(false);
      expect(console.warn).toHaveBeenCalledWith(
        'Usage: node index-files.js <response-file> <source-root>',
      );
    });

    it('should use fallback script name when not provided', () => {
      const args = ['node'];
      const result = validateArguments(args, 3);
      expect(result).toBe(false);
      // When args[1] is undefined, the script name in the message has no value (just empty space)
      expect(console.warn).toHaveBeenCalledWith('Usage: node  <response-file> <source-root>');
    });
  });
});
