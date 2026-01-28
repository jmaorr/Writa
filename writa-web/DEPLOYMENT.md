# Writa Website Deployment Guide

## Overview

This guide covers deploying the Writa website to Cloudflare Pages and hosting the DMG file on Cloudflare R2.

## Prerequisites

1. Cloudflare account
2. Wrangler CLI installed: `npm install -g wrangler`
3. Authenticated with Cloudflare: `wrangler login`

## Step 1: Create R2 Bucket for DMG Hosting

### Create the Bucket

```bash
wrangler r2 bucket create writa-downloads
```

### Upload the DMG

```bash
wrangler r2 object put writa-downloads/Writa-0.1.dmg --file="../Apple App/build/Writa-0.1.dmg" --remote
```

**Important**: Always use the `--remote` flag to upload to Cloudflare's remote R2 (not local).

### Make Bucket Public (Optional - for direct downloads)

In the Cloudflare dashboard:
1. Go to R2
2. Select the `writa-downloads` bucket
3. Go to Settings → Public Access
4. Enable public access
5. Note the public bucket URL (e.g., `https://pub-xxxxx.r2.dev`)

### Set Up Custom Domain (Recommended)

1. In the Cloudflare dashboard, go to R2 → writa-downloads bucket
2. Click "Connect Domain"
3. Enter your domain (e.g., `downloads.writa.app`)
4. Follow the DNS setup instructions

## Step 2: Update Website Download URL

Edit `app/page.tsx` and update the download URL:

```tsx
href="https://downloads.writa.app/Writa-0.1.dmg"
```

Or use the R2 public URL:

```tsx
href="https://pub-xxxxx.r2.dev/Writa-0.1.dmg"
```

## Step 3: Deploy Website to Cloudflare Pages

### Option A: Deploy via Wrangler CLI

```bash
# Build the site
npm run pages:build

# Deploy to Cloudflare Pages
wrangler pages deploy .vercel/output/static --project-name=writa-web
```

### Option B: Deploy via Cloudflare Dashboard

1. Go to Cloudflare Pages
2. Click "Create a project"
3. Connect your Git repository (GitHub, GitLab, etc.)
4. Configure build settings:
   - **Build command**: `npm run pages:build`
   - **Build output directory**: `.vercel/output/static`
   - **Root directory**: `/writa-web` (if in monorepo)
5. Click "Save and Deploy"

### Option C: Deploy via Git (Continuous Deployment)

1. Push your code to GitHub/GitLab
2. Connect the repository to Cloudflare Pages
3. Every push to `main` will automatically deploy

## Step 4: Configure Custom Domain for Website

1. In Cloudflare Pages, go to your project
2. Click "Custom domains"
3. Add your domain (e.g., `writa.app` or `www.writa.app`)
4. Cloudflare will automatically configure DNS

## Step 5: Verify Deployment

1. Visit your website URL
2. Test the download button
3. Verify the DMG downloads correctly
4. Check that all pages load properly

## Updating the Site

### Update DMG File

When you have a new version:

```bash
# Create new DMG
cd "/Users/joshua.orr/Documents/Writa/Apple App"
./Scripts/create-dmg.sh "Notarized Builds/XX/Writa.app"

# Upload to R2
wrangler r2 object put downloads/Writa-X.X.dmg --file="build/Writa-X.X.dmg"

# Update the download URL in app/page.tsx
# Then redeploy the website
```

### Update Website

```bash
# Make your changes
# Then build and deploy
npm run pages:build
wrangler pages deploy .vercel/output/static --project-name=writa-web
```

## Monitoring

### Check Download Stats

You can use Cloudflare Analytics to monitor:
- R2 bandwidth usage
- Number of downloads
- Geographic distribution of users

### Check Website Performance

In Cloudflare Pages dashboard:
- View deployment history
- Check build logs
- Monitor page views and performance

## Troubleshooting

### DMG Download Issues

If downloads aren't working:
1. Check R2 bucket is public or has correct CORS settings
2. Verify the download URL is correct
3. Check browser console for errors

### Website Build Failures

Common issues:
1. Missing dependencies: `npm install`
2. TypeScript errors: Check `npm run lint`
3. Build configuration: Verify `next.config.ts`

### DNS/Domain Issues

1. Verify DNS records are correct in Cloudflare
2. Check SSL/TLS certificate is active
3. Wait for DNS propagation (up to 24 hours)

## Cost Estimate

Cloudflare Free Tier includes:
- ✅ Unlimited Pages deployments
- ✅ R2: 10 GB storage/month
- ✅ R2: 10 million Class A operations/month
- ✅ Unlimited bandwidth for Pages

For a small app like Writa with moderate downloads, this should be completely free!

## Security

### Enable Cloudflare Security Features

1. **DDoS Protection**: Automatically enabled
2. **SSL/TLS**: Always use "Full (strict)" mode
3. **Security Level**: Set to "Medium" or "High"
4. **Bot Fight Mode**: Consider enabling to block malicious bots

## Next Steps

After deployment:
1. Set up Cloudflare Web Analytics (free)
2. Configure email forwarding for support@writa.app
3. Set up redirects if needed (e.g., www to apex domain)
4. Consider setting up a CDN for faster global delivery (automatic with Cloudflare)
