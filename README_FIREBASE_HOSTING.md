# Deploy frontend and route API to Cloud Run via Firebase Hosting

This guide shows how to host the Flutter web frontend (in `web/`) on Firebase Hosting and route `/api/**` to a Cloud Run service running the backend.

High-level steps
1. Deploy your backend to Cloud Run if you have server-side components. Ensure the Cloud Run service is named `municipay-backend` (or update `firebase.json`).
2. Initialize Firebase in the project and configure Hosting or use the provided `firebase.json` and `.firebaserc` files.
3. Build the Flutter web app and deploy Hosting.

Commands

Build Flutter web (from project root):
```bash
flutter build web --release
```

Initialize Firebase (only if not done yet):
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# choose existing project -> YOUR_FIREBASE_PROJECT_ID
```

Deploy Hosting (this will serve `web/` and rewrite `/api/**` to Cloud Run):
```bash
firebase deploy --only hosting
```

Notes and recommendations
- The `firebase.json` included rewrites `/api/**` to the Cloud Run service `municipay-backend` in region `europe-west1`. If you deploy Cloud Run to a different region or service ID, update `firebase.json` accordingly.
- Cloud Run must allow unauthenticated invocations for Hosting rewrites to work without extra IAM configuration, or configure IAP and adjust rewrites to include authentication.
-- Persisting data: Cloud Run containers are ephemeral. Use Cloud SQL (or Firestore) for persistent data. Refer to your Cloud Run deployment documentation or the Google Cloud docs for guidance.

If you want, I can:
- generate a `cloudbuild.yaml` and `gcloud` commands for CI/CD,
- add a Firebase Hosting GitHub Action example for automatic deploys,
- or update `firebase.json` to use a different service/region.
