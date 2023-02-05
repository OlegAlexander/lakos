# Upgrade Checklist

- [ ] Upgrade dart SDK with `choco upgrade dart-sdk` as admin
- [ ] Run `dart pub outdated`
- [ ] Run `dart pub upgrade --major-versions`
- [ ] Remove all ^ in pubspec.yaml
- [ ] Delete pubspec.lock and run `dart pub get`.
- [ ] Modify code as needed
- [ ] Run `dart test` and check the dot_images folder
- [ ] Run `docker system prune -a --volumes -f` and `docker build .`
- [ ] Run example.dart
- [ ] Run `dart doc` and open index.html with Live Server
- [ ] Upgrade lakos version in pubspec.yaml
- [ ] Update CHANGELOG.md
- [ ] Run `dart pub publish --dry-run` and `dart pub publish` (ignore warnings about tight constraints)
- [ ] Run `dart pub global activate lakos` and make sure it's the latest version
- [ ] Commit and push changes to github
