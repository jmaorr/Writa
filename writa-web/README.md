# Writa Website

This is the download website for Writa, built with Next.js and deployed to Cloudflare Pages.

## Getting Started

### Development

First, install dependencies:

```bash
npm install
```

Then run the development server:

```bash
npm run dev
```

Open [http://localhost:3002](http://localhost:3002) in your browser to see the result.

## Building for Production

### Build for Cloudflare Pages

```bash
npm run pages:build
```

This will create a static export in `.vercel/output/static` that's optimized for Cloudflare Pages.

### Deploy to Cloudflare

```bash
npm run pages:deploy
```

Or deploy through the Cloudflare dashboard:

1. Go to Cloudflare Pages
2. Create a new project
3. Connect your git repository or upload the `.vercel/output/static` directory
4. Set build command: `npm run pages:build`
5. Set build output directory: `.vercel/output/static`

## Project Structure

- `app/` - Next.js app directory
  - `page.tsx` - Main landing page
  - `layout.tsx` - Root layout with metadata
  - `globals.css` - Global styles
- `public/` - Static assets (images, icons, etc.)
- `wrangler.toml` - Cloudflare configuration

## Cloudflare R2 Setup (for DMG hosting)

To host the DMG file on Cloudflare R2:

1. **Create R2 bucket**:
   ```bash
   wrangler r2 bucket create writa-downloads
   ```

2. **Create and upload DMG**:
   ```bash
   cd "../Apple App"
   ./Scripts/create-dmg.sh "Notarized Builds/01/Writa.app"
   ./Scripts/upload-to-cloudflare.sh "Notarized Builds/01/Writa-0.1.dmg"
   ```
   (Script automatically uses `--remote` flag)

3. **Connect custom domain** in Cloudflare Dashboard:
   - R2 → writa-downloads → Settings → Connect Domain
   - Enter: `downloads.getwrita.com`

4. The website already uses the correct URL: `https://downloads.getwrita.com/Writa-0.1.dmg`

## Environment Variables

For local development with R2 or other Cloudflare services, create a `.env.local` file:

```env
# Add any necessary environment variables here
```

## Learn More

- [Next.js Documentation](https://nextjs.org/docs)
- [Cloudflare Pages](https://developers.cloudflare.com/pages)
- [Cloudflare R2](https://developers.cloudflare.com/r2)
