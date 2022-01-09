# Upgrade Checklist

- [ ] Upgrade dart SDK with `choco upgrade dart-sdk` as admin
- [ ] Run `dart pub outdated`
- [ ] Run `dart pub upgrade --major-versions`
- [ ] Remove all ^ in pubspec.yaml
- [ ] Modify code as needed
- [ ] Run `dart test` and check the dot_images folder
- [ ] Run `docker system prune -a --volumes -f` and `docker build .`
- [ ] Run example.dart
- [ ] Run `dartdoc` and open index.html with Live Server
- [ ] Upgrade lakos version in pubspec.yaml
- [ ] Update CHANGELOG.md
- [ ] Commit and push changes to github
- [ ] Run `dart pub publish --dry-run` and `dart pub publish` (ignore warnings about tight constraints)
- [ ] Run `dart pub global activate lakos` and make sure it's the latest version
