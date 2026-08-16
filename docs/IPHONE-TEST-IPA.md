# Build Pingo for iPhone without local Xcode

Pingo includes a manual GitHub Actions workflow named **Build iPhone Test IPA**. It uses a GitHub-hosted macOS runner to compile the real-device iOS build without production signing, packages the embedded Messages extension into an IPA, and publishes that IPA as a workflow artifact.

## Build the IPA

1. Open the repository on GitHub.
2. Open **Actions**.
3. Select **Build iPhone Test IPA**.
4. Choose **Run workflow**.
5. Leave `Debug` selected for normal testing and start the run.
6. When the run is green, open it and download the `Pingo-Test-IPA-...` artifact.
7. Unzip the downloaded artifact to get `Pingo-Test.ipa`.

The artifact is intentionally unsigned. Do not upload it to App Store Connect. It is meant to be re-signed for a personal test device by AltServer/AltStore or another legitimate personal-development signing tool.

## Install with AltServer

1. Install AltServer on the Mac and install AltStore to the iPhone.
2. Connect the iPhone to the Mac and enable Developer Mode on the iPhone.
3. In AltServer, use the option to sideload an IPA and select `Pingo-Test.ipa`.
4. AltServer signs the container and embedded `PingoMessagesExtension.appex` with the Apple account used for personal development.
5. Open Messages on the iPhone and find Pingo in the Messages app list.

Free personal-development provisioning normally expires periodically, so the app may need to be refreshed/re-signed.

## What the workflow validates

- Xcode project generation succeeds.
- The build targets `iphoneos`, not the simulator.
- Code signing is disabled only during the cloud compilation step.
- `Pingo.app` exists in the device build products.
- `PingoMessagesExtension.appex` is embedded inside the app.
- The final `Pingo-Test.ipa` is non-empty and contains the Messages extension.

## Production releases

This workflow is separate from `.github/workflows/app-store-release.yml`. Production/TestFlight builds still require real Apple distribution credentials, provisioning, production service URLs, and App Store Connect setup.
