# FaceAuth

FaceAuth is a macOS face-unlock project with a companion website. The website introduces the app and includes its FAQ, privacy policy, requirements, and support pages.

> **Security note:** FaceAuth is a convenience feature, not a replacement for Apple's Face ID or Touch ID. A Mac camera captures a 2D image, so face recognition may be less secure than Apple's biometric authentication. Review the app's [README](./faceauth%20app/README.md) before installing or using it.

## Repository contents

- Website pages and assets are in the repository root.
- The native macOS app and its Xcode project are in [`faceauth app/`](./faceauth%20app/).
- React and TypeScript components used by the site are in [`components/`](./components/).

## Website development

The website uses Vite, TypeScript, React, and npm.

### Requirements

- Node.js and npm
- macOS 15 Sequoia or later, Apple silicon or Intel Mac, and a camera to use the native app

### Run locally

From the repository root:

```bash
npm install
npm run build
npx vite --host 127.0.0.1
```

Open the local URL printed by Vite. The build command type-checks the TypeScript and generates the site's UI bundles in `generated/`.

## Native macOS app

The app's requirements, installation instructions, privacy details, security limitations, and Xcode build steps are documented in [`faceauth app/README.md`](./faceauth%20app/README.md). Open [`faceauth app/faceauth.xcodeproj`](./faceauth%20app/faceauth.xcodeproj) in Xcode to work on the app.

## License

See the app's [LICENSE](./faceauth%20app/LICENSE).
