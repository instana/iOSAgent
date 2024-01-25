# Contributing

## How to Contribute

This is an open source project, and we appreciate your help!

Each source file must include this license header:

```
/*
 * (c) Copyright IBM Corp. 2024
 */
```

Furthermore you must include a sign-off statement in the commit message.

> Signed-off-by: John Doe <john.doe@example.com>

### Please note that in the case of the below-mentioned scenarios, follow the specified steps:
- **Proposing New Features**: Vist the ideas portal for [Cloud Management and AIOps](https://automation-management.ideas.ibm.com/?project=INSTANA) and post your idea to get feedback from IBM. This is to avoid you wasting your valuable time working on a feature that the project developers are not interested in accepting into the code base.
- **Raising a Bug**: Please visit [IBM Support](https://www.ibm.com/mysupport/s/?language=en_US) and open a case to get help from our experts.
- **Merge Approval**: The codeowners use LGTM (Looks Good To Me) in comments on the code review to indicate acceptance. A change requires LGTMs from two of the members. Request review from @instana/eng-eum for approvals.

Thank you for your interest in the Instana iOS project!

## Pull Request Process

1. Add or update the UnitTests accordingly
2. Make sure to follow the SwiftLint rules
3. Avoid any build warning
4. Update the README.md with details of changes to the interface, this includes new environment
   variables, exposed ports, useful file locations and parameters.
5. Update the Changelog.md with details of changes


## Release version
Please make sure to follow the semantic versioning rules.
1. Update version in `InstanaAgent.podspec` (`s.version = "<Your Version>"`)
2. Update version in VersionConfig.Swift
3. Update InstanaSystemUtilsTests test_AgentVersion.
4. Update CHANGELOG.md accordingly
5. Run tests via `sh scripts/run-unit-tests.sh`
6. Run `git tag <Your Version> && git push origin <Your Version>`
7. Run `pod trunk push InstanaAgent.podspec --allow-warnings`
8. Make a release note on the Github page
9. Update cross platform frameworks accordingly (Flutter / ReactNative / Xamarin)

## Code of Conduct

### Our Pledge

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to making participation in our project and
our community a harassment-free experience for everyone, regardless of age, body
size, disability, ethnicity, gender identity and expression, level of experience,
nationality, personal appearance, race, religion, or sexual identity and
orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment
include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery and unwelcome sexual attention or
advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or electronic
  address, without explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

### Our Responsibilities

Project maintainers are responsible for clarifying the standards of acceptable
behavior and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions
that are not aligned to this Code of Conduct, or to ban temporarily or
permanently any contributor for other behaviors that they deem inappropriate,
threatening, offensive, or harmful.

### Scope

This Code of Conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community. Examples of
representing a project or community include using an official project e-mail
address, posting via an official social media account, or acting as an appointed
representative at an online or offline event. Representation of a project may be
further defined and clarified by project maintainers.
