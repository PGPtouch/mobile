symbols_dir := "build/symbols"
_obfuscation := "--obfuscate --split-debug-info=" + symbols_dir

# List available recipes
default:
    @just --list

# Install dependencies
get:
    flutter pub get

# Run the code generation and image generation tasks
gen: gitbaker codegen

# Regenerate the git metadata file (lib/generated/gitbaker.g.dart)
gitbaker:
    dart run gitbaker

# Run code generation (drift, etc.)
codegen:
    dart run build_runner build

# Static analysis
analyze:
    flutter analyze --no-fatal-infos

# Run tests
test:
    flutter test

# Format Dart sources
format:
    dart format lib test

# Remove build artifacts and refetch dependencies
clean:
    flutter clean
    flutter pub get

# Build an obfuscated release APK
build-apk *args: gen
    flutter build apk --release {{ _obfuscation }} {{ args }}

# Build an obfuscated release APK per ABI
build-apk-split *args: gen
    flutter build apk --release --split-per-abi {{ _obfuscation }} {{ args }}

# Build an obfuscated release app bundle (Play Store)
build-aab *args: gen
    flutter build appbundle --release {{ _obfuscation }} {{ args }}

# Default Android build: obfuscated release APK
build *args: (build-apk args)
