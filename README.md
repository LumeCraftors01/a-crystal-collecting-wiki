# Crystal Collecting Simulator: complete setup

Files in this folder
- `crystalcsxmain.html`: the main page (loads at `/`)
- `community.html`: the community page (loads at `/community`), already set to your Supabase project
- `worker.js` + `wrangler.toml` + `.assetsignore`: the Cloudflare Worker that serves the two pages
- `supabase-setup.sql`: the database setup. Already run once. Not needed in the repo.

## 1. GitHub repo (top folder, no subfolders)
`crystalcsxmain.html`, `community.html`, `worker.js`, `wrangler.toml`, `.assetsignore`
- Open `wrangler.toml` and make `name` match your Worker's name in Cloudflare exactly.
- Delete any older `wrangler.jsonc` / `wrangler.toml` so there is only one config.

## 2. Cloudflare
Connected to the repo, it rebuilds on every commit. Check Workers & Pages > your project > Deployments for Success.

## 3. Supabase (Authentication > URL Configuration)
- Site URL: `https://YOUR-ADDRESS/community`
- Redirect URLs: `https://YOUR-ADDRESS/**`

## 4. Test, in this order
1. `/` loads, the loading screen finishes, the Community icon in the top bar opens a new tab.
2. `/community` shows "Join the community" with no yellow "not connected" box.
3. Sign up > confirm email > log in > post an image > refresh, it is still there.
4. Private window: the post shows, the upload form does not.
5. Second account: like and report the post.
6. Make yourself moderator in the Supabase SQL Editor (use your username):
   `update public.profiles set is_admin = true where username = 'YourUsername';`
7. Privacy and account > Delete my account works on a test account.

## 5. Before opening it to players
- Connect a real email sender (Authentication > SMTP Settings). The built-in one allows only a few emails an hour.
- Turn "Confirm email" back ON if you switched it off for testing.
- Players are often under 13. The page asks for a 13+ confirmation, but check what the law requires where you operate.
- Images are not scanned. Check the Reported posts panel regularly.
- Fill `CONTACT` in `community.html` so people can reach you.

## If something fails
- "Invalid API key": replace the key in `community.html` with the legacy `anon` key (Supabase > API Keys > Legacy tab).
- Build fails on name: fix `name` in `wrangler.toml`.
- 404 on `/community`: check `worker.js` and `wrangler.toml` are in the top folder.
