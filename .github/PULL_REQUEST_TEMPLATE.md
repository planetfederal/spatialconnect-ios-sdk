## Status
**READY/IN DEVELOPMENT/HOLD**

## JIRA Ticket
The ticket id

## Description
A few sentences describing the overall goals of the pull request's commits.

## Todos
- [ ] Tests
- [ ] Documentation
- [ ] License

## Steps to Test or Reproduce
Outline the steps to test or reproduce the PR here.

```sh
git fetch --all
git checkout <feature_branch> 
xctool -workspace SpatialConnect.xcworkspace -scheme SpatialConnect -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6 Plus' ONLY_ACTIVE_ARCH=NO test
```

@boundlessgeo/spatial-connect
