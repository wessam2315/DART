# DART — Connect the World

This bundle contains the DART front-end prototype (Arabic RTL, mobile-first).

## Included
- Feed, demo posts, likes, comments and local post creation
- Explore/search demo profiles and follow toggles
- Demo messaging (local only, not real network messaging)
- Profile editing
- PWA manifest and basic offline shell

## Deploy with GitHub Pages
1. Create a GitHub repository.
2. Upload `index.html`, `manifest.json`, and `sw.js` to the repository root.
3. Repository Settings -> Pages -> Deploy from a branch -> choose `main` and `/ (root)`, save.
4. Wait for the Pages URL to appear. Share that URL.

## Important limitations
This is a front-end prototype. Data is saved only in the current browser using local storage.
Demo profiles are sample content. Messages are not sent to other users.
For a public production app, add server-side authentication, database, real-time messaging,
image storage, abuse reporting/moderation, privacy policy, and secure backend rules.
