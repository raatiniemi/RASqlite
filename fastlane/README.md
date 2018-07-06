fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios lint
```
fastlane ios lint
```
Lint project files
### ios clean_release_build
```
fastlane ios clean_release_build
```
Build a release version of the framework
### ios test
```
fastlane ios test
```
Run tests and generate coverage reports
### ios metrics
```
fastlane ios metrics
```
Collect metrics and send it to SonarQube for analysis

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
