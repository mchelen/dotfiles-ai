# Testing

**Start from a failing test that captures the expected behavior, then write the
code that makes it pass — and show me both runs.**

- Write tests **before** implementation by default: start from a failing test
  that captures the expected behavior, then write the code to make it pass.
- Show me the failing test run before the fix and the passing run after —
  that's the evidence the test actually exercises the change.
- When fixing a bug, first add a test that reproduces it.
- Test behavior, not implementation details; don't write tests that just
  mirror the code's internals or mock everything into meaninglessness.
- Use the project's existing test framework and conventions. If the project
  has no test setup at all, propose one before introducing it.

Skip test-first when:

- It's a throwaway spike, mockup, or exploration (per the feature workflow)
- The change isn't meaningfully testable (docs, comments, formatting, config)
- I've explicitly said to skip tests
