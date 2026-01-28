# Writa Website - Quick Start

## 🚀 Test Locally (Before Deploying)

```bash
cd "/Users/joshua.orr/Documents/Writa/writa-web"
npm run dev
```

Then open: **http://localhost:3002**

---

## 📦 Deploy to Cloudflare

### First Time Setup

1. **Install Wrangler** (if not already installed):
   ```bash
   npm install -g wrangler
   ```

2. **Login to Cloudflare**:
   ```bash
   wrangler login
   ```

3. **Create R2 Bucket** (if not already created):
   ```bash
   wrangler r2 bucket create writa-downloads
   ```

4. **Create DMG from notarized app**:
   ```bash
   cd "/Users/joshua.orr/Documents/Writa/Apple App"
   ./Scripts/create-dmg.sh "Notarized Builds/01/Writa.app"
   ```

5. **Upload to remote R2**:
   ```bash
   ./Scripts/upload-to-cloudflare.sh "Notarized Builds/01/Writa-0.1.dmg"
   ```
   (Script automatically uses `--remote` flag)

6. **Connect R2 to Custom Domain**:
   - Go to Cloudflare Dashboard
   - Navigate to R2 → writa-downloads bucket
   - Settings → Connect Domain
   - Enter: `downloads.getwrita.com`

7. The website already uses the correct URL:
   ```tsx
   href="https://downloads.getwrita.com/Writa-0.1.dmg"
   ```

8. **Build the website**:
   ```bash
   cd "/Users/joshua.orr/Documents/Writa/writa-web"
   npm run pages:build
   ```

9. **Deploy to Cloudflare Pages**:
   ```bash
   wrangler pages deploy .vercel/output/static --project-name=writa-web --commit-dirty=true
   ```

10. **Set up custom domain**:
    - In Cloudflare Pages dashboard
    - Go to your writa-web project
    - Custom domains → Add `getwrita.com` and `www.getwrita.com`

---

## 🔄 Update Workflow (After First Deploy)

When you have a new version:

```bash
# 1. Create new DMG from notarized app
cd "/Users/joshua.orr/Documents/Writa/Apple App"
./Scripts/create-dmg.sh "Notarized Builds/XX/Writa-X.X.app"

# 2. Upload to R2
./Scripts/upload-to-cloudflare.sh "Notarized Builds/XX/Writa-X.X.dmg"

# 3. Update website download URL and version in app/page.tsx

# 4. Rebuild and deploy
cd ../writa-web
npm run pages:build
wrangler pages deploy .vercel/output/static --project-name=writa-web
```

---

## 📋 Pre-Deployment Checklist

Before deploying to production:

- [ ] DMG is notarized ✅
- [ ] DMG tested on clean Mac
- [ ] R2 bucket is public
- [ ] Download URL updated in website
- [ ] Website tested locally (`npm run dev`)
- [ ] Website builds successfully (`npm run build`)
- [ ] Download button tested
- [ ] Looks good on mobile & desktop

---

## 🆘 Common Issues

### "wrangler: command not found"
```bash
npm install -g wrangler
```

### "Not authenticated with Cloudflare"
```bash
wrangler login
```

### Build errors
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
npm run build
```

### DMG download doesn't work
- Check R2 bucket has custom domain connected (downloads.getwrita.com)
- Verify download URL in `app/page.tsx` matches the R2 domain
- Ensure DMG was uploaded with `--remote` flag
- Check browser console for errors

---

## 📚 More Info

- Full deployment guide: `DEPLOYMENT.md`
- Project overview: `README.md`
- Complete summary: `../DEPLOYMENT_SUMMARY.md`
