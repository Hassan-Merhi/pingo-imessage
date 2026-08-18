# Build Pingo for iPhone without local Xcode

Pingo includes a manual GitHub Actions workflow named **Build iPhone Test IPA**. It uses a GitHub-hosted macOS runner to compile the real-device iOS build without production signing, packages the embedded Messages extension into an IPA, and publishes that IPA as a workflow artifact.

## Build the IPA

1. Open the repository on GitHub.
2. Open **Actions**.
3. Select **Build iPhone Test IPA**.
4. Choose **Run workflow**.
5. Start the run. The workflow always builds the sideload-safe **Release** configuration.
6. When the run is green, open it and download the `Pingo-Test-Release-IPA-...` artifact.
7. Unzip the downloaded artifact to get `Pingo-Test-Release.ipa`.

The artifact is intentionally unsigned. Do not upload it to App Store Connect. It is meant to be re-signed for a personal test device by AltServer/AltStore or another legitimate personal-development signing tool.

The sideload workflow deliberately uses Release rather than Debug. Current Xcode Debug device builds may contain `*.debug.dylib` and `__preview.dylib` loader files that some third-party personal signing tools do not re-sign correctly. The workflow fails if those debug dylibs appear in the packaged app.

## Install with a personal-development signing tool

1. Connect the iPhone to the computer and enable Developer Mode on the iPhone.
2. Open your personal-development signing tool.
3. Select `Pingo-Test-Release.ipa`.
4. Make sure the tool preserves and signs embedded app extensions; Pingo requires `Pingo Messages.appex`.
5. Sign/install the IPA for the connected iPhone.
6. Open Messages on the iPhone and find Pingo in the Messages app list.

Free personal-development provisioning normally expires periodically, so the app may need to be refreshed/re-signed.

## What the workflow validates

- Xcode project generation succeeds.
- The build targets `iphoneos`, not the simulator.
- The build uses Release configuration.
- Code signing is disabled only during the cloud compilation step.
- `Pingo.app` exists in the device build products.
- `Pingo Messages.appex` is embedded inside the app.
- No `*.debug.dylib` or `__preview.dylib` files are present.
- The main app and Messages extension executables contain arm64 device code.
- The extension principal class is `Pingo_Messages.MessagesViewController`.
- The final `Pingo-Test-Release.ipa` is non-empty and contains the Messages extension.

## Production releases

This workflow is separate from `.github/workflows/app-store-release.yml`. Production/TestFlight builds still require real Apple distribution credentials, provisioning, production service URLs, and App Store Connect setup.
