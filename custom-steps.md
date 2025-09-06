# Complete List of Linker Custom Steps in .NET for Android

The .NET for Android build system uses the ILLink trimmer with several custom steps that are configured in `Microsoft.Android.Sdk.ILLink.targets`. Here's the complete list organized by execution phase:

## Steps that run during MarkStep (Custom MarkHandlers)

1. **`Microsoft.Android.Sdk.ILLink.PreserveSubStepDispatcher`**
   - Dispatcher for managing sub-steps during the mark phase
   - File: `src/Microsoft.Android.Sdk.ILLink/PreserveSubStepDispatcher.cs`

2. **`MonoDroid.Tuner.MarkJavaObjects`** → **`Microsoft.Android.Sdk.ILLink.MarkJavaObjects`**
   - Marks Java objects that need to be preserved 
   - File: `src/Microsoft.Android.Sdk.ILLink/MarkJavaObjects.cs`

3. **`MonoDroid.Tuner.PreserveJavaExceptions`** → **`Microsoft.Android.Sdk.ILLink.PreserveJavaExceptions`**
   - Preserves Java exception types to maintain proper exception handling
   - File: `src/Microsoft.Android.Sdk.ILLink/PreserveJavaExceptions.cs`

4. **`MonoDroid.Tuner.PreserveApplications`** → **`Microsoft.Android.Sdk.ILLink.PreserveApplications`**
   - Preserves Android Application classes and their members
   - File: `src/Microsoft.Android.Sdk.ILLink/PreserveApplications.cs`

5. **`Microsoft.Android.Sdk.ILLink.PreserveRegistrations`**
   - Preserves types marked with registration attributes (e.g., `[Register]`)
   - File: `src/Microsoft.Android.Sdk.ILLink/PreserveRegistrations.cs`

6. **`Microsoft.Android.Sdk.ILLink.PreserveJavaInterfaces`**
   - Preserves Java interface implementations
   - File: `src/Microsoft.Android.Sdk.ILLink/PreserveJavaInterfaces.cs`

7. **`MonoDroid.Tuner.FixAbstractMethodsStep`**
   - Fixes abstract method implementations for Android binding scenarios
   - File: `src/Xamarin.Android.Build.Tasks/Linker/MonoDroid.Tuner/FixAbstractMethodsStep.cs`

## Steps that run BeforeStep="MarkStep"

8. **`MonoDroid.Tuner.FixLegacyResourceDesignerStep`** (conditional)
   - Fixes legacy Resource.Designer issues when `$(AndroidUseDesignerAssembly)` is true
   - File: `src/Xamarin.Android.Build.Tasks/Linker/MonoDroid.Tuner/FixLegacyResourceDesignerStep.cs`

## Steps that run AfterStep="CleanStep"  

9. **`Mono.Linker.Steps.GenerateProguardConfiguration`** → **`Microsoft.Android.Sdk.ILLink.GenerateProguardConfiguration`** (conditional)
   - Generates ProGuard configuration when `$(_ProguardProjectConfiguration)` is set
   - File: `src/Microsoft.Android.Sdk.ILLink/GenerateProguardConfiguration.cs`

10. **`MonoDroid.Tuner.AddKeepAlivesStep`** (conditional)
    - Adds keep-alive annotations when `$(AndroidAddKeepAlives)` is true
    - File: `src/Xamarin.Android.Build.Tasks/Linker/MonoDroid.Tuner/AddKeepAlivesStep.cs`

11. **`MonoDroid.Tuner.StripEmbeddedLibraries`** → **`Microsoft.Android.Sdk.ILLink.StripEmbeddedLibraries`**
    - Removes embedded native libraries from assemblies
    - File: `src/Microsoft.Android.Sdk.ILLink/StripEmbeddedLibraries.cs`

12. **`MonoDroid.Tuner.RemoveResourceDesignerStep`** (conditional)
    - Removes Resource.Designer when `$(AndroidLinkResources)` is true
    - File: `src/Xamarin.Android.Build.Tasks/Linker/MonoDroid.Tuner/RemoveResourceDesignerStep.cs`

13. **`MonoDroid.Tuner.GetAssembliesStep`** → **`Microsoft.Android.Sdk.ILLink.GetAssembliesStep`** (conditional)
    - Collects assemblies for processing when `$(AndroidLinkResources)` is true  
    - File: `src/Microsoft.Android.Sdk.ILLink/GetAssembliesStep.cs`

14. **`Microsoft.Android.Sdk.ILLink.TypeMappingStep`** (conditional)
    - Generates type mappings when `$(_AndroidTypeMapImplementation)` is 'managed'
    - File: `src/Microsoft.Android.Sdk.ILLink/TypeMappingStep.cs`

## SubSteps (run as part of PreserveSubStepDispatcher)

15. **`Microsoft.Android.Sdk.ILLink.ApplyPreserveAttribute`**
    - Applies preserve attributes during linking
    - File: `src/Microsoft.Android.Sdk.ILLink/ApplyPreserveAttribute.cs`

16. **`Microsoft.Android.Sdk.ILLink.PreserveExportedTypes`**
    - Preserves exported types
    - File: `src/Microsoft.Android.Sdk.ILLink/PreserveExportedTypes.cs`

## Additional Steps (not directly referenced in targets but part of the pipeline)

17. **`MonoDroid.Tuner.FindJavaObjectsStep`**
    - Assembly modifier pipeline step for finding Java objects
    - File: `src/Xamarin.Android.Build.Tasks/Linker/MonoDroid.Tuner/FindJavaObjectsStep.cs`

18. **`MonoDroid.Tuner.FindTypeMapObjectsStep`** 
    - Assembly modifier pipeline step for finding type map objects
    - File: `src/Xamarin.Android.Build.Tasks/Linker/MonoDroid.Tuner/FindTypeMapObjectsStep.cs`

## Base Classes

- **`LinkDesignerBase`** - Abstract base for designer-related steps
- **`RemoveAttributesBase`** - Abstract base for attribute removal steps

## Execution Order

The steps are executed in this order during the linking process:
1. BeforeStep="MarkStep" steps
2. MarkStep with custom MarkHandlers and SubSteps
3. AfterStep="CleanStep" steps

Each step serves a specific purpose in ensuring Android applications are properly linked while preserving the necessary types and members for Android interop functionality.

## Configuration

All custom steps are configured in:
- `src/Xamarin.Android.Build.Tasks/Microsoft.Android.Sdk/targets/Microsoft.Android.Sdk.ILLink.targets`

The steps use the `$(_AndroidLinkerCustomStepAssembly)` assembly which contains all the custom step implementations.

## Removal Strategy Analysis

### Steps Running During MarkStep (Most Problematic)

These steps run during the marking phase and can influence what gets trimmed. They need special consideration as they may generate code or dependencies that should participate in trimming.

**1. PreserveSubStepDispatcher + SubSteps**
- **ApplyPreserveAttribute**: ✅ **EASY** - Can be replaced with injecting `DynamicDependencyAttribute` before MarkStep
- **PreserveExportedTypes**: ✅ **EASY** - Can be replaced with injecting `DynamicDependencyAttribute` before MarkStep

**2. MarkJavaObjects**: ⚠️ **COMPLEX** 
- Marks types based on complex logic (custom views, HttpClientHandler, IJniNameProviderAttribute)
- Could be replaced with pre-analysis + `DynamicDependencyAttribute` injection
- Alternative: Move to separate Cecil-based tool that runs on all IL before trimming

**3. PreserveJavaExceptions**: ✅ **EASY**
- Simple logic: "if type extends Java exception, preserve string constructor"  
- Can be replaced with `DynamicDependencyAttribute` on exception types before MarkStep

**4. PreserveApplications**: ✅ **MEDIUM**
- Preserves types referenced in `ApplicationAttribute` properties
- Can be replaced with build-time analysis + `DynamicDependencyAttribute` injection

**5. PreserveRegistrations**: ⚠️ **COMPLEX**
- Preserves methods based on `[Register]` attributes and JNI marshal methods
- Complex cross-type dependencies and marshal method generation
- Best moved to separate Cecil tool that processes all IL

**6. PreserveJavaInterfaces**: ✅ **EASY** 
- Simple logic: "if interface implements IJavaObject, preserve all members"
- Can be replaced with `DynamicDependencyAttribute` before MarkStep

**7. FixAbstractMethodsStep**: ⚠️ **MODERATE**
- Generates new methods (throws `AbstractMethodError`)
- Could move to separate Cecil tool, but needs to ensure generated methods participate in trimming
- Alternative: Pre-generate methods before trimming starts

### Steps Running BeforeStep="MarkStep" (Easiest)

**8. FixLegacyResourceDesignerStep**: ✅ **VERY EASY**
- Runs on all IL before trimming
- Can move directly to separate Cecil-based tool

### Steps Running AfterStep="CleanStep" (Easy to Moderate)

These run on post-trimming IL, so they're candidates for separate tools.

**9. GenerateProguardConfiguration**: ✅ **VERY EASY**
- Only reads metadata to generate ProGuard config
- Can move to separate Cecil tool that runs on trimmed output

**10. AddKeepAlivesStep**: ✅ **EASY**
- Adds attributes to prevent GC collection  
- Can move to separate Cecil tool on trimmed output

**11. StripEmbeddedLibraries**: ✅ **VERY EASY**
- Removes embedded resources (jars, zips)
- Can move to separate Cecil tool on trimmed output

**12. RemoveResourceDesignerStep**: ✅ **EASY** 
- Removes Resource.Designer types
- Can move to separate Cecil tool on trimmed output

**13. GetAssembliesStep**: ✅ **EASY**
- Collects assembly information
- Can move to separate Cecil tool on trimmed output

**14. TypeMappingStep**: ✅ **EASY**
- Generates type mappings for NativeAOT
- Can move to separate Cecil tool on trimmed output

### Additional Pipeline Steps

**15. FindJavaObjectsStep**: ✅ **EASY**
- Assembly modifier - can run in separate tool before trimming

**16. FindTypeMapObjectsStep**: ✅ **EASY** 
- Assembly modifier - can run in separate tool before trimming

## Recommended Removal Strategy

### Phase 1: Easy Wins (AfterStep + BeforeStep)
1. Move all AfterStep steps to separate Cecil tool (9-14)
2. Move BeforeStep steps to separate Cecil tool (8, 15, 16)

### Phase 2: MarkStep Simple Cases  
1. Replace with `DynamicDependencyAttribute` injection (3, 6, parts of 4)
2. Pre-analyze and inject attributes (1 - SubSteps)

### Phase 3: Complex MarkStep Cases
1. Move complex steps to separate pre-trimming Cecil tool (2, 5, 7)
2. Ensure any generated code participates in trimming via attributes

### Tools Architecture
- **Pre-trimming tool**: Runs Cecil on all IL, handles complex analysis, injects `DynamicDependencyAttribute`
- **Post-trimming tool**: Runs Cecil on trimmed IL, handles cleanup operations
- **MSBuild integration**: Inject tools at appropriate points in build pipeline

## Testing Strategy for Custom Step Removal

### Available Test Suites

**1. Unit Tests (Fast, Isolated)**
- Location: `src/Xamarin.Android.Build.Tasks/Tests/Xamarin.Android.Build.Tests/Tasks/LinkerTests.cs`
- Run with: `dotnet-local.cmd test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter ClassName=LinkerTests`
- Tests specific custom steps like `FixAbstractMethodsStep`, `MarkJavaObjects`, etc.
- Perfect for testing individual step logic changes

**2. Integration Tests (Medium Speed, End-to-End)**
- Location: `src/Xamarin.Android.Build.Tasks/Tests/Xamarin.Android.Build.Tests/`
- Run with: `dotnet-local.cmd test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter TestName~Trim`
- Tests full build pipeline with trimming scenarios
- Key tests: `PreserveCustomHttpClientHandlers`, `AndroidAddKeepAlives`, `RemoveDesigner`, `LinkDescription`

**3. APK Size Regression Tests (Critical for Trimming Balance)**
- Location: `src/Xamarin.Android.Build.Tasks/Tests/Xamarin.Android.Build.Tests/BuildTest2.cs`
- Key Test: `BuildReleaseArm64` (tests simple and Xamarin.Forms apps)
- Run with: `./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter FullyQualifiedName~BuildReleaseArm64`
- **Purpose**: Detects when trimming is insufficient (APK sizes increase) or excessive (crashes)
- **Thresholds**: 5KB or 3% APK size increase triggers failure
- **Reference Files**: `src/Xamarin.Android.Build.Tasks/Tests/Xamarin.ProjectTools/Resources/Base/*.apkdesc`

**4. Device Tests (Slow, Real Device)**
- Location: `tests/MSBuildDeviceIntegration/Tests/InstallAndRunTests.cs`
- Key Test: `CustomLinkDescriptionPreserve` with `AndroidLinkMode.Full`/`AndroidLinkMode.SdkOnly`
- **Purpose**: Verifies apps don't crash from over-trimming on real devices
- **Note**: Requires emulator/device and full build environment

**5. Sample Projects (Manual Testing)**
- Location: `samples/HelloWorld/`, `samples/NativeAOT/`
- Run with tasks: `prepare-sample-under-dotnet`, `build-sample-under-dotnet`, `run-sample-under-dotnet`

### Prerequisites for Integration Tests

The integration tests require a properly configured .NET Android workload. You have two options:

**Option A: Full Build (Recommended for comprehensive testing)**
```bash
# This builds everything including workloads - takes ~30+ minutes
make all
```

**Option B: Environment Setup Only (Faster for quick testing)**
```bash
# 1. Setup Android toolchain (takes ~5 minutes)
dotnet build-server shutdown
./build-tools/xaprepare/xaprepare/bin/Debug/net9.0/xaprepare --s=AndroidTestDependencies --android-sdk-platforms="28,29,30,31,32,33,34,35,36"
dotnet build build-tools/Xamarin.Android.Tools.BootstrapTasks/Xamarin.Android.Tools.BootstrapTasks.csproj -c Debug

# 2. Build native runtime (required for workload)
./dotnet-local.sh build src/native/native-mono.csproj -c Debug

# 3. Create and configure workload (alternative to downloading CI artifacts)
make create-nupkgs  # This will fail but creates necessary components
# OR try: dotnet build build-tools/create-packs/Microsoft.Android.Sdk.proj -t:ExtractWorkloadPacks -c Debug
```

**Important**: Integration tests fail with `NETSDK1147: android workload must be installed` if the workload isn't properly configured.

### Recommended Smoke Test Approach

**Phase 1: Basic Functionality (Fast - works without full workload setup)**
```bash
# These tests work immediately after building test assemblies:

# 1. Check available linker-related tests
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --list-tests | grep -E "(PreserveCustom|LinkDescription|RemoveDesigner|AndroidAddKeepAlive)"

# 2. Run APK size regression test (this validates trimming balance)
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "FullyQualifiedName~BuildReleaseArm64"
```

**Phase 2: Integration Tests (Requires workload setup from Prerequisites)**
```bash
# 1. Run specific linker integration tests
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "FullyQualifiedName~PreserveCustomHttpClientHandlers"
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "FullyQualifiedName~LinkDescription"
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "FullyQualifiedName~RemoveDesigner"
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "FullyQualifiedName~AndroidAddKeepAlives"
```

**Phase 2: Comprehensive Validation**
```bash
# 4. Run all trimming-related tests
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "FullyQualifiedName~RemoveDesigner|FullyQualifiedName~AndroidAddKeepAlives"

# 5. Run device tests (requires emulator/device + full build)
# Note: Device tests require workload to be built first
./dotnet-local.sh test bin/TestDebug/MSBuildDeviceIntegration/net9.0/MSBuildDeviceIntegration.dll --filter "FullyQualifiedName~CustomLinkDescriptionPreserve"

# 6. Check APK size regressions (critical for production)
# This test ensures trimming isn't too aggressive (causing crashes) or too conservative (bloating APKs)
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "Name~BuildReleaseArm64"
```

**Phase 3: Understanding the Trimming Balance**

The testing strategy ensures the right balance between two failure modes:

1. **Over-Trimming (Crashes)**: Device tests verify apps still work after aggressive linking
2. **Under-Trimming (Bloat)**: APK size regression tests catch when trimming is insufficient

```bash
# 7. Performance validation (optional)
time ./dotnet-local.sh build samples/HelloWorld/HelloWorld/HelloWorld.DotNet.csproj -c Release

# 8. Manual APK size comparison (when reference files need updating)
# Reference files: src/Xamarin.Android.Build.Tasks/Tests/Xamarin.ProjectTools/Resources/Base/
# Update script: build-tools/scripts/UpdateApkSizeReference.ps1
```

**Note**: If PR tests are green, the trimming balance is likely correct - neither breaking functionality nor bloating APKs unnecessarily.
```bash
# 6. Measure build times with/without changes
# Use `time` command or VS Code task timing
time ./dotnet-local.sh build samples/HelloWorld/HelloWorld/HelloWorld.DotNet.csproj -c Release -p:PublishTrimmed=true

# 7. Compare APK sizes
ls -lah samples/HelloWorld/HelloWorld/bin/Release/net*/*-Signed.apk
```

### Key Test Scenarios to Focus On

1. **MarkJavaObjects**: Custom views, HttpClientHandler, IJavaObject types
2. **PreserveRegistrations**: `[Register]` attributes, JNI marshal methods  
3. **FixAbstractMethodsStep**: Interface implementation, abstract method generation
4. **StripEmbeddedLibraries**: JAR/ZIP resource removal
5. **AddKeepAlivesStep**: GC.KeepAlive injection
6. **Resource linking**: Designer class removal
7. **APK Size Regression**: `BuildReleaseArm64` test ensures trimming balance
   - Detects over-trimming (crashes) vs under-trimming (bloat)
   - Uses `apkdiff` tool with 5KB/3% thresholds
   - Reference files: `src/Xamarin.Android.Build.Tasks/Tests/Xamarin.ProjectTools/Resources/Base/*.apkdesc`

### Automation for Development Workflow

Create a script `test-custom-steps.sh`:
```bash
#!/bin/bash
set -e

echo "=== Testing Custom Step Changes ==="

# Fast smoke test (< 2 minutes) - works without workload setup
echo "1. Checking available linker tests..."
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --list-tests | grep -E "(PreserveCustom|LinkDescription|RemoveDesigner|AndroidAddKeepAlive)" | head -5

echo "2. Running APK size regression test (validates trimming balance)..."
./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "FullyQualifiedName~BuildReleaseArm64" || echo "Note: May fail without full build environment"

# Integration tests (requires workload setup)
if [ "$1" = "--full" ]; then
    echo "3. Running integration tests (requires workload)..."
    ./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "FullyQualifiedName~PreserveCustomHttpClientHandlers"
    ./dotnet-local.sh test bin/TestDebug/net9.0/Xamarin.Android.Build.Tests.dll --filter "FullyQualifiedName~LinkDescription"
    echo "4. Building sample with trimming..."
    time ./dotnet-local.sh build samples/HelloWorld/HelloWorld/HelloWorld.DotNet.csproj -c Release -p:PublishTrimmed=true
fi

echo "=== Smoke test complete ==="
```

Usage:
- `./test-custom-steps.sh` - Fast smoke test (< 2 min)
- `./test-custom-steps.sh --full` - Full integration test (requires workload setup)

This gives you a fast smoke test for each change, plus comprehensive options for deeper validation when the workload is properly set up.
