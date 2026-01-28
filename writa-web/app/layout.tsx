import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Writa - AI-Powered Writing Assistant for macOS",
  description: "Beautiful, intelligent writing assistant for macOS. Enhance your writing with AI-powered suggestions, grammar checking, and seamless integration.",
  keywords: "writing app, AI writing, macOS app, writing assistant, grammar checker, text editor",
  authors: [{ name: "Orriginal" }],
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: '32x32' },
      { url: '/favicon-16.png', sizes: '16x16', type: 'image/png' },
      { url: '/favicon-32.png', sizes: '32x32', type: 'image/png' },
    ],
    apple: [
      { url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' },
    ],
  },
  openGraph: {
    title: "Writa - AI-Powered Writing Assistant",
    description: "Beautiful, intelligent writing assistant for macOS",
    url: "https://getwrita.com",
    siteName: "Writa",
    images: [{ url: '/icon-512.png', width: 512, height: 512 }],
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.className} antialiased`}>
        {children}
      </body>
    </html>
  );
}
