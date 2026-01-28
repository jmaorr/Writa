# Writa Project

AI-powered writing assistant for macOS.

## 🚀 Quick Start

**New here?** → Read **[START_HERE.md](START_HERE.md)**

## 📁 Project Structure

```
Writa/
├── 📱 Apple App/              macOS application
│   ├── Writa/                Xcode project
│   ├── Scripts/              Deployment scripts
│   └── Notarized Builds/     Distribution builds
│
├── 🌐 writa-web/             Download website
│   ├── app/                  Next.js pages
│   └── public/               Static assets
│
└── 📚 Documentation/         Guides & references
```

## 📚 Documentation Index

### Getting Started
- **[START_HERE.md](START_HERE.md)** - Begin here! Current status & next steps
- **[COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md)** - Full deployment walkthrough

### Reference Guides
- **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - Quick overview of setup
- **[writa-web/QUICK_START.md](writa-web/QUICK_START.md)** - Website quick reference
- **[writa-web/DEPLOYMENT.md](writa-web/DEPLOYMENT.md)** - Detailed website deployment
- **[writa-web/README.md](writa-web/README.md)** - Website development

### Scripts & Tools
- **[Apple App/Scripts/README_DMG_CREATION.md](Apple App/Scripts/README_DMG_CREATION.md)** - Creating DMGs
- **[Apple App/Scripts/README_UPLOAD.md](Apple App/Scripts/README_UPLOAD.md)** - Uploading to R2
- **[Apple App/Scripts/create-dmg.sh](Apple App/Scripts/create-dmg.sh)** - DMG creation script
- **[Apple App/Scripts/upload-to-cloudflare.sh](Apple App/Scripts/upload-to-cloudflare.sh)** - R2 upload script

## 🌐 Live URLs

- **Website**: https://writa-web.pages.dev → https://getwrita.com (add custom domain)
- **Download**: https://downloads.getwrita.com/Writa-0.1.dmg (after R2 domain setup)
- **Support**: support@getwrita.com

## ⚡ Common Tasks

### Create DMG from Notarized App
```bash
cd "Apple App"
./Scripts/create-dmg.sh "Notarized Builds/01/Writa.app"
```

### Upload DMG to Cloudflare R2
```bash
cd "Apple App"
./Scripts/upload-to-cloudflare.sh "Notarized Builds/01/Writa-0.1.dmg"
```

### Deploy Website
```bash
cd writa-web
npm run pages:build
wrangler pages deploy .vercel/output/static --project-name=writa-web --commit-dirty=true
```

### Test Website Locally
```bash
cd writa-web
npm run dev
# Opens at http://localhost:3002
```

## 🔄 Update Workflow

For new versions, see **[COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md#future-updates)**

Quick version:
1. Archive & notarize in Xcode
2. Create DMG: `./Scripts/create-dmg.sh "path/to/Writa.app"`
3. Upload: `./Scripts/upload-to-cloudflare.sh "path/to/Writa.dmg"`
4. Update website version in `writa-web/app/page.tsx`
5. Redeploy website

## 🛠️ Tech Stack

### macOS App
- Swift
- SwiftUI
- macOS 14.0+

### Website
- Next.js 15
- React 19
- Tailwind CSS
- TypeScript
- Cloudflare Pages

### Infrastructure
- Cloudflare R2 (DMG hosting)
- Cloudflare Pages (website hosting)
- Custom domains on Cloudflare

## ✅ Current Status

- [x] DMG packaging configured
- [x] Upload scripts configured (uses `--remote`)
- [x] Website built and deployed
- [x] DMG uploaded to remote R2
- [x] All documentation complete
- [ ] R2 custom domain connected (manual step)
- [ ] Website custom domain added (manual step)

**See [START_HERE.md](START_HERE.md) for next steps.**

## 💰 Hosting Cost

**FREE** - Everything runs on Cloudflare's free tier! 🎉

- Cloudflare Pages: Unlimited deployments
- Cloudflare R2: 10 GB storage (only using 6.7 MB)
- Bandwidth: Unlimited

## 🆘 Support

- **Questions?** Check the documentation index above
- **Issues?** See troubleshooting in COMPLETE_DEPLOYMENT_GUIDE.md
- **Email**: support@getwrita.com

---

© 2025 Orriginal. All rights reserved.
