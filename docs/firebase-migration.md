# Firebase migration

The app uses Firebase Authentication and Cloud Firestore for student, family,
and school access. Supabase remains configured as a backup; this migration does
not copy Supabase users or data. Users create a new Firebase account, and old
Supabase passwords cannot be transferred.

## Firestore rules

Run the rules tests locally with:

```sh
npm install
npm run test:rules
```

After reviewing the changes and confirming the Firebase project is `sqeducaplay`,
publish the rules with:

```sh
firebase deploy --only firestore:rules --project sqeducaplay
```

Do not publish permissive test rules. The test suite uses the local emulator and
a `demo-` project ID; it does not connect to the production project.

## First platform administrator

The app intentionally does not allow a client to grant itself administrator
access. To bootstrap the first platform administrator:

1. Create a family account in the app using the administrator's email.
2. In Firebase Console > Authentication, copy that account's UID.
3. In Firestore, open `users/{UID}` and change its `role` field from `guardian`
   to `admin`.
4. Sign in again through **Sou Educador**. The administrator can then register
   schools and assign school administrators.

The `users/{UID}` document is created by the app when the family account is
registered; do not create it with an unrelated UID.
