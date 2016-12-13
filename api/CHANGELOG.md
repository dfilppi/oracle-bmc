# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/).

## 1.0.1
### Fixed
- Accept header set to json only, since some 500 responses were sent in other formats and caused deserialization failures.

### Added
- Signing now includes the signing version number with each request.
- Example code is now packaged in the zip file.

## 1.0.0 - 2016-10-20
### Added
- Initial Release
- Support added for Core Services and Identity Service
