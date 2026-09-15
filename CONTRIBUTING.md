Contributing to ChefSpec
========================
Pull requests are merged via GitHub. If you're new to contributing, see GitHub's guide on [forking a repository](https://docs.github.com/en/get-started/quickstart/fork-a-repo) to get started.

All contributions are welcome to be submitted for review for inclusion, but before they will be accepted, we ask that you follow these simple steps:

* [Coding standards](#coding-standards)
* [Testing](#testing)
* [Documentation](#documentation)

Also, please be patient as not all items will be tested or reviewed immediately by the core team.

Please be receptive and responsive to feedback about your additions or changes. The core team and/or other community members may make suggestions or ask questions about your change. This is part of the review process, and helps everyone to understand what is happening, why it is happening, and potentially optimizes your code.

If you're looking to contribute but aren't sure where to start, check out the [open issues](https://github.com/chef/chefspec/issues).


Will Not Merge
--------------
This section details, specifically, Pull Requests or features that will _not_ be merged:

1. Matchers for non-Chef core resources. ChefSpec provides a way for cookbook maintainers to ship [custom matchers](https://github.com/chef/chefspec#chefspec-matchers) _with_ their cookbooks at distribution time.
2. New features without accompanying unit tests and documentation.


Coding Standards
----------------
ChefSpec's code style is enforced with [Cookstyle](https://docs.chef.io/workstation/cookstyle/). Before submitting a pull request, please run the linter and fix any offenses:

```sh
bundle exec rake style
```

This runs the same `cookstyle --chefstyle -c .rubocop.yml` check used in CI.


Testing
-------
Whether your pull request is a bug fix or introduces new classes or methods to the project, we kindly ask that you include tests for your changes. Even if it's just a small improvement, a test is necessary to ensure the bug is never re-introduced.

ChefSpec has two test suites, both runnable with Rake:

```sh
bundle exec rake unit        # fast RSpec unit tests in spec/
bundle exec rake acceptance  # end-to-end example cookbooks in examples/
bundle exec rake test        # run both
```

We understand that not all users submitting pull requests will be proficient with RSpec. The maintainers and community as a whole are a helpful group and can help you with writing tests. The [Better Specs](https://www.betterspecs.org/) site provides some helpful resources to get you started.

ChefSpec is tested in [GitHub Actions](https://github.com/chef/chefspec/actions) against multiple Ruby versions. **Your patches must pass for all Ruby versions in the CI matrix.** This is in an effort to maintain backward compatibility as long as possible. See the [`.github/workflows/ci.yml`](https://github.com/chef/chefspec/blob/main/.github/workflows/ci.yml) file for the currently supported versions.


Documentation
-------------
Documentation is a crucial part to ChefSpec, especially given its broad depth of features. All documentation is placed inline on the method matcher so it can be generated with [YARD](https://yardoc.org/). Please see existing matchers for an example.

When contributing new features, please ensure adequate documentation and examples are present.

**Every public class, module, constant, attribute, and method in `lib/` should carry a YARD comment.** You can check this before opening a pull request:

```sh
bundle exec rake yard:coverage  # report anything public that is undocumented
bundle exec rake yard           # build the HTML docs into doc/
```

`rake yard:coverage` exits non-zero and names the offending `file:line` when something is missing, so it can also be wired into a local pre-commit hook if you find that useful.

A few conventions worth knowing:

- Docstrings use **RDoc markup**, not Markdown. Wrap inline code in plus signs (`+template+`), not backticks.
- Use `{ChefSpec::Matchers::LinkToMatcher}` to link to something defined in this gem. For classes that live in another gem, such as `+Chef::Resource+` or `+Mash+`, use plus signs — YARD cannot resolve a link to a class it has not parsed, and doing so adds a build warning.
- A docstring made up of nothing but tags counts as undocumented. `# @api private` on its own will not satisfy the check; add a sentence explaining what the object is for alongside the tag.
- Private and protected methods are not required to have comments, though they are welcome.
