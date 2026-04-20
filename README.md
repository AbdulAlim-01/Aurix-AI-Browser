# Aurix Browser 🚀

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Gemini](https://img.shields.io/badge/Google_Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)

Aurix Browser is a next-generation, AI-integrated mobile web browser built with Flutter. It combines traditional browsing with advanced AI capabilities powered by Google Gemini and a robust backend by Supabase.

---
<img src="https://api.crazzy.dev/upload/images/banner.png"/>
## 📸 Screenshots
<img src="https://api.crazzy.dev/upload/images/1.png" width="500" />
<img src="https://api.crazzy.dev/upload/images/2.png"  width="500" />
<img src="https://api.crazzy.dev/upload/images/3.png"  width="500"/>
<img src="https://api.crazzy.dev/upload/images/4.png" width="500" />
<img src="https://api.crazzy.dev/upload/images/5.png" width="500"/>
---

## ✨ Features

- 🤖 **AI-Powered Search & Interaction**: Integrated Gemini AI for real-time summaries, analysis, and research directly from your browser.
- 💬 **Multi-Tab Contextual Chat**: Chat with AI while referencing multiple open tabs simultaneously. Perfect for comparative research.
- ✍️ **Social Media Content Generator**: Generate high-quality posts, replies, and threads for X (Twitter), LinkedIn, Reddit, and Instagram based on the webpage you're visiting.
- 🎭 **AI Profiles (Personas)**: Create and switch between different AI personas to tailor the AI's tone and expertise to your specific needs.
- 📹 **YouTube & Article Summarization**: Get instant summaries of long YouTube videos or dense articles with a single click.
- 🛡️ **Incognito & Secure**: Browse privately with Incognito mode and secure authentication via Supabase.
- 📑 **Advanced Tab Management**: Seamlessly switch between tabs with a beautiful, glassmorphic UI.
- ☁️ **Cloud Sync**: Sync your bookmarks, history, and AI profiles across devices using Supabase.
- 📥 **Download Manager**: Track and manage your downloads within the app.
- 🎨 **Glassmorphic UI**: A modern, sleek design with support for both Light and Dark modes.

---

## 🛠️ Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/)
- **AI Engine**: [Google Gemini API](https://deepmind.google/technologies/gemini/)
- **Backend/Database**: [Supabase](https://supabase.com/)
- **WebView**: [InAppWebView](https://pub.dev/packages/flutter_inappwebview)
- **State Management**: Provider-like (ChangeNotifier)
- **Storage**: Shared Preferences & Supabase

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK
- Android Studio / VS Code
- Supabase Project
- Google Gemini API Key

### Configuration

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/aurix_browser.git
    cd aurix_browser
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Setup Environment Variables:**
    Open `lib/app_constant.dart` and replace the placeholders with your actual credentials:
    ```dart
    static const String SUPABASE_URL = 'YOUR_SUPABASE_URL';
    static const String SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
    static const String GEMINI_API_KEY = 'YOUR_GEMINI_API_KEY';
    ```

4.  **Supabase Database Setup:**
    Execute the SQL provided in `lib/supabaseConstant.dart` in your Supabase SQL Editor to initialize the necessary tables (`profiles`, `bookmarks`, `downloads`, `ai_profiles`, etc.).

5.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📧 Contact

Your Name - [@AbdulAlim](https://x.com/CrazzyAlim) - mraalim6838@gmail.com

