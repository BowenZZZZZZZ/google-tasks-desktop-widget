# Google OAuth Setup

The app uses the Google Tasks API with a read-only scope:

```text
https://www.googleapis.com/auth/tasks.readonly
```

Each user should create their own Google Cloud OAuth Desktop client.

## 1. Create Or Select A Google Cloud Project

Open:

```text
https://console.cloud.google.com/
```

Create a project, or select an existing personal project.

## 2. Enable Google Tasks API

Open the API Library and enable **Google Tasks API**:

```text
https://console.cloud.google.com/apis/library/tasks.googleapis.com
```

## 3. Configure Google Auth Platform

Open:

```text
https://console.cloud.google.com/auth/overview
```

If prompted to configure the app:

- App name: `Google Tasks Desktop`
- User support email: your Google account email
- Audience: `External`
- Contact email: your Google account email
- Accept the Google API Services User Data Policy if you agree

For testing mode, add your Google account under **Audience** → **Test users**.

## 4. Add The Tasks Readonly Scope

Open **Data access**:

```text
https://console.cloud.google.com/auth/scopes
```

Click **Add or remove scopes**. If Tasks readonly is not visible, manually add:

```text
https://www.googleapis.com/auth/tasks.readonly
```

Save the data access changes.

## 5. Create OAuth Desktop Client

Open **Clients**:

```text
https://console.cloud.google.com/auth/clients
```

Create a client:

- Application type: `Desktop app`
- Name: `Google Tasks Desktop macOS`

Copy:

- Client ID
- Client secret

Paste both into the app Settings, then click **Sign in**.

## Notes

- Do not commit client secrets.
- If the app is in Google testing mode, only configured test users can sign in.
- Google may show an unverified-app warning for personal testing apps.
