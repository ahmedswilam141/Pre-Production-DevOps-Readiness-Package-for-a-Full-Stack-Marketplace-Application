# Known Limitations

## ⚠️ Infrastructure & Deployment
- **Build Connectivity**: The current environment experiences intermittent network failures during `yarn install` inside Docker containers. This prevents a full successful build of the images in some environments.
- **Database Credentials**: The `docker-compose.yml` uses a default password (`password`). This must be changed in `.env` before any production deployment.
- **Frontend API URL**: The frontend currently uses `http://localhost/api` by default. In a production environment, this needs to be updated to the actual domain via `VITE_API_URL`.

## ⚠️ Application Logic
- **AI Model Cold Start**: The first AI analysis request may take significantly longer as TensorFlow loads the MobileNet model into memory.
- **State Persistence**: Only the PostgreSQL database is persisted. Any local file uploads would be lost on container recreation.

## ⚠️ Pre-existing Application Bugs (TS Errors)
The following TypeScript errors prevent the frontend from building (`yarn build` fails). These are business logic / type-definition issues and not DevOps errors:
- **Type Mismatches**: 
  - `src/components/Ads/Filter.tsx`: `null` passed where `string | number | boolean` is expected.
  - `src/components/Ads/Pagination.tsx`: Parameter type mismatch in page handler.
  - `src/components/User/Content/AccountSettings.tsx`: `undefined` passed to `Date` constructor.
- **Missing Properties**:
  - `src/components/Ads/PrevAdCard.tsx`: `is_sell_ad` missing from `IntrinsicAttributes`.
  - `src/components/Sidebar/Sidebar.tsx`: `to` property missing in `NavItemProps`.
- **Implicit 'any' Types**:
  - Multiple files including `src/components/Login/Login.tsx`, `src/components/User/SummaryBar/Data.tsx`, and `src/components/User/SummaryBar/Profile.tsx`.
- **Case Sensitivity**: `src/components/Chats/ChatBox.tsx` has inconsistent casing for `Chat.service` imports.

## ⚠️ Third-Party Dependencies
- **Stripe**: Requires a valid webhook secret and a running listener for payment events to trigger.
- **Twilio**: Requires an active Twilio account and a Verify Service SID to function.
- **Firebase**: The frontend has Firebase configuration placeholders; these must be replaced with a real Firebase project for authentication/storage features to work.
- **Email**: Requires a valid SMTP server (e.g., Gmail with App Password) to send notifications.
