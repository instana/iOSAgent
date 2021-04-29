# Contributing

This is an open source project, and we appreciate your help!

In order to clarify the intellectual property license granted with contributions from any person or entity, a Contributor License Agreement ("CLA") must be on file that has been signed by each contributor, indicating agreement to the license terms below. This license is for your protection as a contributor as well as the protection of Instana and its customers; it does not change your rights to use your own contributions for any other purpose.

Please print, fill out, and sign the contributor license agreement. Once completed, please scan the document as a PDF file and email to the following email address: bastian.krol@instana.com.

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method with the owners of this repository before making a change.

Please note we have a code of conduct, please follow it in all your interactions with the project.

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
2. Update version in VersionConfig.Swift and update InstanaSystemUtilsTests. Use [SemVer](http://semver.org/).
3. Update the test_AgentVersion according to the new version
4. Update CHANGELOG.md accordingly
5. Run `git tag <Your Version> && git push origin <Your Version>`
6. Run `pod trunk push InstanaAgent.podspec --allow-warnings`
7. Make a release note on the Github page
8. Update cross platform frameworks accordingly (Flutter / ReactNative / Xamarin)

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

