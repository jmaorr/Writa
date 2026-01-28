export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-blue-50 dark:from-gray-900 dark:via-gray-900 dark:to-gray-800 overflow-x-hidden">
      
      {/* Hero Section */}
      <div className="relative w-full pb-16">
        
        {/* Hero Content */}
        <div className="relative z-10 max-w-6xl mx-auto px-6 pt-32 text-center">
          
          {/* Early Access Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white text-sm font-medium mb-6 shadow-sm backdrop-blur-md">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-purple-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-purple-500"></span>
            </span>
            Beta Release
          </div>

          <h1 className="text-5xl md:text-8xl font-bold mb-8 text-gray-900 dark:text-white tracking-tight">
            Writa
          </h1>
          
          <p className="text-xl md:text-2xl text-gray-600 dark:text-gray-300 mb-12 max-w-2xl mx-auto leading-relaxed">
            Your AI-powered writing companion.
            Write better, faster, and more confidently with intelligent assistance.
          </p>

          {/* Download Button Area */}
          <div className="flex flex-col items-center gap-4 mb-20">
            <a
              href="https://downloads.getwrita.com/Writa-0.2.dmg"
              className="group relative px-8 py-4 bg-purple-600 hover:bg-purple-700 text-white font-semibold rounded-2xl shadow-xl hover:shadow-2xl hover:shadow-purple-500/30 transition-all duration-300 flex items-center gap-3 transform hover:-translate-y-1"
            >
              <div className="absolute inset-0 rounded-2xl bg-gradient-to-tr from-purple-500 to-purple-400 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              <svg className="w-6 h-6 relative z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
              <span className="text-lg relative z-10">Download for Mac</span>
              <span className="text-sm bg-purple-700/50 px-2 py-1 rounded-md relative z-10 border border-purple-400/30">v0.2 Beta</span>
            </a>
            
            <div className="text-sm text-gray-600 dark:text-gray-400 font-medium flex items-center gap-2">
              <span>7.5 MB</span>
              <span className="w-1 h-1 rounded-full bg-gray-400" />
              <span>macOS 14.0+</span>
              <span className="w-1 h-1 rounded-full bg-gray-400" />
              <span>Apple Silicon</span>
            </div>
          </div>

            {/* Feature Cards Grid */}
            <div className="grid md:grid-cols-2 gap-6 max-w-5xl mx-auto mb-24 text-left">
                
                {/* Feature 1: AI-Powered */}
                <div className="group relative overflow-hidden p-8 rounded-3xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 hover:border-purple-500/50 dark:hover:border-purple-500/50 transition-all duration-500 hover:shadow-2xl hover:shadow-purple-500/10">
                    <div className="h-48 mb-6 relative flex items-center justify-center bg-gradient-to-br from-purple-50 to-blue-50 dark:from-gray-900 dark:to-gray-800 rounded-2xl overflow-hidden">
                        <div className="relative">
                            <svg className="w-24 h-24 text-purple-600 dark:text-purple-400 transform group-hover:scale-110 transition-transform duration-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                            </svg>
                            <div className="absolute -top-2 -right-2 w-4 h-4 bg-purple-400 rounded-full animate-ping" />
                        </div>
                    </div>
                    <h3 className="text-2xl font-bold mb-2 text-gray-900 dark:text-white">AI-Powered Assistance</h3>
                    <p className="text-gray-600 dark:text-gray-400">Get intelligent writing suggestions, grammar corrections, and style improvements powered by advanced AI.</p>
                </div>

                {/* Feature 2: Beautiful Interface */}
                <div className="group relative overflow-hidden p-8 rounded-3xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 hover:border-blue-500/50 dark:hover:border-blue-500/50 transition-all duration-500 hover:shadow-2xl hover:shadow-blue-500/10">
                    <div className="h-48 mb-6 relative flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800 rounded-2xl overflow-hidden">
                        <div className="relative w-full h-full flex flex-col items-center justify-center gap-2 p-6">
                            <div className="w-full h-3 bg-blue-200 dark:bg-blue-900/50 rounded-full transform -translate-x-4 group-hover:translate-x-0 transition-transform duration-500" />
                            <div className="w-4/5 h-3 bg-blue-300 dark:bg-blue-800/50 rounded-full transform translate-x-4 group-hover:translate-x-0 transition-transform duration-500 delay-75" />
                            <div className="w-full h-3 bg-blue-200 dark:bg-blue-900/50 rounded-full transform -translate-x-2 group-hover:translate-x-0 transition-transform duration-500 delay-150" />
                        </div>
                    </div>
                    <h3 className="text-2xl font-bold mb-2 text-gray-900 dark:text-white">Beautiful Interface</h3>
                    <p className="text-gray-600 dark:text-gray-400">Distraction-free writing environment with a clean, modern design that adapts to your workflow.</p>
                </div>

                {/* Feature 3: Native macOS */}
                <div className="group relative overflow-hidden p-8 rounded-3xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 hover:border-green-500/50 dark:hover:border-green-500/50 transition-all duration-500 hover:shadow-2xl hover:shadow-green-500/10">
                    <div className="h-48 mb-6 relative flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50 dark:from-gray-900 dark:to-gray-800 rounded-2xl overflow-hidden">
                        <div className="relative">
                            <svg className="w-24 h-24 text-green-600 dark:text-green-400 transform group-hover:rotate-12 transition-transform duration-500" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                            </svg>
                        </div>
                    </div>
                    <h3 className="text-2xl font-bold mb-2 text-gray-900 dark:text-white">Native macOS App</h3>
                    <p className="text-gray-600 dark:text-gray-400">Built specifically for macOS with full support for native features, keyboard shortcuts, and system integration.</p>
                </div>

                {/* Feature 4: Privacy First */}
                <div className="group relative overflow-hidden p-8 rounded-3xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 hover:border-orange-500/50 dark:hover:border-orange-500/50 transition-all duration-500 hover:shadow-2xl hover:shadow-orange-500/10">
                    <div className="h-48 mb-6 relative flex items-center justify-center bg-gradient-to-br from-orange-50 to-red-50 dark:from-gray-900 dark:to-gray-800 rounded-2xl overflow-hidden">
                        <div className="relative w-24 h-24">
                            <div className="absolute inset-0 flex items-center justify-center z-10">
                                <svg className="w-12 h-12 text-orange-500 transform group-hover:scale-110 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                                </svg>
                            </div>
                            <div className="absolute inset-0 border-4 border-orange-200 dark:border-orange-900/50 rounded-full animate-[spin_8s_linear_infinite]" />
                            <div className="absolute inset-2 border-4 border-orange-100 dark:border-orange-900/30 rounded-full animate-[spin_12s_linear_infinite_reverse]" />
                        </div>
                    </div>
                    <h3 className="text-2xl font-bold mb-2 text-gray-900 dark:text-white">Privacy Focused</h3>
                    <p className="text-gray-600 dark:text-gray-400">Your writing stays private. All processing happens securely with end-to-end encryption.</p>
                </div>

            </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-6 pb-24">
        
        {/* System Requirements */}
        <div className="bg-white dark:bg-gray-800/50 rounded-2xl p-8 border border-gray-200 dark:border-gray-700 backdrop-blur-sm">
          <h2 className="text-2xl font-bold mb-6 text-center text-gray-900 dark:text-white">System Requirements</h2>
          <div className="grid md:grid-cols-2 gap-6 max-w-3xl mx-auto">
            <div>
              <h3 className="font-semibold mb-2 flex items-center gap-2 text-gray-900 dark:text-white">
                <svg className="w-5 h-5 text-purple-600" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
                Operating System
              </h3>
              <p className="text-gray-600 dark:text-gray-400">macOS 14.0 (Sonoma) or later</p>
            </div>
            
            <div>
              <h3 className="font-semibold mb-2 flex items-center gap-2 text-gray-900 dark:text-white">
                <svg className="w-5 h-5 text-purple-600" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
                Processor
              </h3>
              <p className="text-gray-600 dark:text-gray-400">Apple Silicon or Intel Mac</p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <footer className="mt-20 pt-8 border-t border-gray-200 dark:border-gray-800 text-center text-gray-600 dark:text-gray-400">
          <p className="mb-4">© 2025 Orriginal. All rights reserved.</p>
          <div className="flex justify-center gap-6 text-sm">
            <a href="/privacy" className="hover:text-purple-600 transition-colors">Privacy Policy</a>
            <a href="mailto:support@getwrita.com" className="hover:text-purple-600 transition-colors">Support</a>
          </div>
        </footer>
      </main>
    </div>
  );
}
