#
# Nuqta engine for iOS: the Nuqta core + C ABI compiled here, llama.cpp (with
# mtmd and Metal) linked from a prebuilt llama.xcframework.
#
# Build the framework once before `pod install` / `flutter build ios`:
#   packages/nuqta_engine/tool/build_ios_xcframework.sh
#
Pod::Spec.new do |s|
  s.name             = 'nuqta_engine'
  s.version          = '1.0.0'
  s.summary          = 'On-device Nuqta-OCR through llama.cpp.'
  s.description      = 'Runs the Nuqta-OCR 0.8B GGUF model on the iPhone GPU (Metal) via llama.cpp and dart:ffi.'
  s.homepage         = 'https://github.com/aitasadduq/arabic-ocr'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'arabic-ocr' => 'noreply@github.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{h,c,cpp,mm}'
  s.vendored_frameworks = 'Frameworks/llama.xcframework'
  s.frameworks       = 'Foundation', 'Metal', 'MetalKit', 'Accelerate'
  s.library          = 'c++'
  s.dependency 'Flutter'
  s.platform = :ios, '16.4'

  headers = '"${PODS_TARGET_SRCROOT}/../src" "${PODS_TARGET_SRCROOT}/../src/upstream" ' \
            '"${PODS_TARGET_SRCROOT}/Frameworks/llama.xcframework/ios-arm64/llama.framework/Headers"'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'HEADER_SEARCH_PATHS' => headers,
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) NUQTA_LLAMA_COMMIT=\"5aeac37a35b44fde4bdffaec9159f2fcb253b622\"',
    'GCC_OPTIMIZATION_LEVEL' => 's',
    # CocoaPods copies the matching xcframework slice here but does not link it
    # into this pod's own (dynamic) framework.
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_XCFRAMEWORKS_BUILD_DIR}/nuqta_engine"',
    'OTHER_LDFLAGS' => '$(inherited) -framework llama',
  }
  s.swift_version = '5.0'
end
