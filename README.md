# TinyMind 🚀

**TinyMind** is a lightweight, locally‑run AI‑enhanced keyboard input tool for macOS. It captures your keystrokes, applies on‑the‑fly layout correction using a compact LLM (SmolLM2-360M-Instruct) running on Apple Metal, and delivers a smoother typing experience without any network latency.

---

## ✨ Features

- **Local AI inference** – No internet required; runs entirely on your Mac’s GPU (Apple Metal).
- **Deferred buffer clearing** – Allows hot‑key‑triggered correction immediately after a space or enter.
- **Fast, low‑memory footprint** – Only ~100 MiB of GPU memory used (Metal Compute Buffer is only 99.75 MiB).
- **Easy hot‑key configuration** – Customize hot‑keys via the macOS menu bar.
- **Open‑source** – Fully available on GitHub, ready for you to fork or contribute.

---

## 📦 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/q0022/TinyMind.git
   cd TinyMind
   ```
2. **Install Flutter** (if you haven’t already). Follow the official guide: https://flutter.dev/docs/get-started/install
3. **Fetch dependencies**
   ```bash
   flutter pub get
   ```
4. **Run the app on macOS**
   ```bash
   flutter run -d macos
   ```
   The app will appear as a menu‑bar item.

---

## 📦 Download

Pre‑built release binaries are available as **.dmg** and **.zip** files. Download the latest version from the GitHub Releases page.

[Download latest release](https://github.com/q0022/TinyMind/releases/latest)

---

## 🛠️ Usage

- Type normally; the AI will suggest corrections based on the previous buffer.
- Press your configured hot‑key (default: `⌥` + `Space`) to accept the suggestion.
- The **deferred buffer clear** ensures that a space does **not** clear the buffer until the first character of the next word is typed, preserving hot‑key responsiveness.

---

## 🙏 Credits

- **เจน (Gemini Antigravity)** – Conceptual design, AI model integration, and buffer‑handling logic.
- **คุณพี่บอย** – Project vision, UI/UX decisions, and testing.

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## 🎉 Contributing

We welcome pull requests! If you’d like to improve the AI model, add new hot‑keys, or polish the UI, feel free to fork the repo and submit a PR.

---

*Happy typing with TinyMind!*
