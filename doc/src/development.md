# Developer Guidelines

This document explains the process for development on this project. We are using a PR model, so file an issue on the repo proposing your change so that the developers can discuss and provide early feedback, then make a pull request with your changes. Tag the relevant developers with their names in the comments on the PR so their attension can be called to the PR. Shorter PRs get reviewed faster and get more meaningful feedback.

## Code Style

1. Docstrings on every function and type
2. Use multiple dispatch or default arguments
3. Use logging with key word arguments for example, `@info("Inserting new vertex into graph", vertex=v)`

## Testing

1. Every file in /src should have a test in /test
2. Put tests in their own test set
3. Tests are an opportunity to add usage examples

## Documentation

1. Every concept should have an example in the docs.
2. If you need to add a page to the HTML docs add it as `/doc/src/file.md` and add the corresponding line in `/doc/make.jl`
3. Make sure the docs build locally before merging with master
4. Install graphviz locally so that you can test the `.dot` files.

## Code of Conduct

Be nice. Answer questions and provide feedback on PRs and Issues. Help out with what you can, and ask questions about what you don't understand.
