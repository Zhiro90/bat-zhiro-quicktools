# 🛠️ Zhiro QuickTools

A bunch of `.bat` scripts to handle mundane, repetitive media tasks (conversions, trimming, captioning, etc.) with a single click.

I made these to use with my **Right Click Menu** (Context Menu), but they work just as well via the Windows **SendTo** folder. No fancy GUIs, just drag, drop, and done.

[![Download](https://img.shields.io/github/v/release/Zhiro90/bat-zhiro-quicktools?style=for-the-badge&label=DOWNLOAD&color=232323&logo=windows)](https://github.com/Zhiro90/bat-zhiro-quicktools/releases/latest)

## ⚡ The Quick List

### 📀 Mixed Media
* **CAPTION4ALL:** Add meme-style captions or text overlays to pictures or videos.
* **CROP4ALL:** Smart cropping and padding (16:9, 1:1, etc.) for pictures or videos.
* **TRIM4ALL:** Trim video/audio files (Precise re-encode or Fast stream copy).

### 🎵 Audio
* **EXTRACT320:** One-click extraction to MP3 320kbps (No UI).
* **CONV4AUDIO:** Smart converter (MP3, Opus, FLAC).
* **SONG2VID:** Create a video from an audio file (uses embedded art or local images).

### 🎥 Video
* **VID2x264:** One click converter to H.264/AAC. WhatsApp friendly (No UI).
* **CONV4VID:** Multi-format video converter (MP4, WebM) with resolution resizing.
* **HARDSUB4VID:** Burn subtitles (SRT/ASS) into video.
* **VID2GIFWEBP:** Create optimized GIFs or WebPs from video.
* **FRAMES4ALL:** Extract frames from video or explode GIFs/WebPs.
  
### 🖼️ Image
* **PIC2ALL:** Convert images to PNG, WebP, ICO, or JPG.
* **JOINVERT:** Join multiple images vertically or horizontally.

### 📄 Docs & Utils
* **PASTE2FILE:** Instantly saves your clipboard text to a timestamped `.txt` file.
* **OCRPDF:** Add searchable text layers to PDFs (requires Python).
* **COMIC2PDF:** Convert CBZ/CBR to PDF (and vice-versa).

---

## 📖 Script Details & Usage

Click on a script name to see what it does.

### 📀 Mixed Media Tools
<details>
<summary><strong>Universal Caption Tool (CAPTION4ALL.bat)</strong></summary>

* **What it does:** Adds text to media.
* **Usage:** Adds subtitles/captions with customizable background box, font, and position, works for both pictures (includes some presets) and videos.
</details>

<details>
<summary><strong>Smart Crop & Fill (CROP4ALL.bat)</strong></summary>

* **What it does:** Crops images/videos or fills the background to match a ratio (1:1, 16:9, etc.).
* **Usage:** Send a file.
    * *Video:* Input manual crop percentage.
    * *Image:* Choose presets (Square, Portrait, Landscape) or manual crop.
</details>

<details>
<summary><strong>Media Trimmer (TRIM4ALL.bat)</strong></summary>

* **What it does:** Cuts audio or video files.
* **Usage:** Send a file.
    * *Precise Mode:* Re-encodes the file (frame accurate).
    * *Fast Mode:* Type `copy` to just slice the file without re-encoding (extremely fast, but cuts on keyframes).
</details>

### 🎵 Audio Tools
<details>
<summary><strong>Quick MP3 Extract (extract320.bat)</strong></summary>

* **What it does:** Bruteforce extraction/conversion to MP3 320kbps.
* **Usage:** Send file. No menu. Silent execution.
</details>

<details>
<summary><strong>Smart Audio Converter (CONV4AUDIO.bat)</strong></summary>

* **What it does:** Converts audio files to MP3, Opus, or FLAC.
* **Usage:** Send files. Choose format.
    * *Note:* FLAC option only appears if input is WAV.
</details>

<details>
<summary><strong>Audio to Video (SONG2VID.bat)</strong></summary>

* **What it does:** Turns an MP3/FLAC into an MP4 video (for song sharing to video-only platforms).
* **Logic:**
    1.  Looks for embedded cover art.
    2.  Looks for `folder.jpg` or same-name image in the folder.
    3.  Looks for animations (`.gif`/`.webp`) to loop.
    4.  Falls back to a default image (comes in the package).
</details>

### 🎥 Video Tools
<details>
<summary><strong>Quick Video Converter (VID2x264.bat)</strong></summary>

* **What it does:** Forces a video into standard H.264 + AAC format to ensure compatibility with older devices and Whatsapp web.
* **Usage:** Just send the file. No menu, fully automatic.
</details>

<details>
<summary><strong>Multi-Format Converter (CONV4VID.bat)</strong></summary>

* **What it does:** Converts videos to MP4 (H.264) or WebM (VP9).
* **Usage:** Send a video file. A menu asks for the target format and resolution (1080p, 720p, 480p, etc.).
</details>

<details>
<summary><strong>Frame Extractor (FRAMES4ALL.bat)</strong></summary>

* **What it does:** Dumps every frame of a video/gif into a folder.
* **Usage:** Send file. It handles GIF coalescing automatically (so frames aren't garbled).
</details>

<details>
<summary><strong>Hardsub Burner (HARDSUB4VID.bat)</strong></summary>

* **What it does:** Burns subtitles permanently into the video.
* **Usage:** Send a video.
    * It automatically looks for a matching `.srt` or `.ass` file.
    * If none found, it scans for internal subtitle tracks.
    * Lets you choose font styles (Cinema Yellow, Simple White, Custom).
</details>

<details>
<summary><strong>Animation Converter (VID2GIFWEBP.bat)</strong></summary>

* **What it does:** Turns short videos into high-quality GIFs or efficient WebPs.
* **Usage:** Send video(s). Choose format (GIF/WebP) and optional FPS/Quality settings.
</details>

### 🖼️ Image Tools
<details>
<summary><strong>Image Converter (PIC2ALL.bat)</strong></summary>

* **What it does:** Converts images to PNG, WebP, ICO (multisize), or JPG.
* **Usage:** Send image(s). Select output format from the menu.
</details>

<details>
<summary><strong>Smart Image Joiner (JOINVERT.bat)</strong></summary>

* **What it does:** Stitches multiple images together cleanly through a very caveman-like way (the only way i was able to make it work with bat files). Calling joinvert.ps1 and joinvert_real.bat
* **Usage:** Select multiple images -> Send to script.
    * Asks if you want to join them Vertically (Tall) or Horizontally (Wide).
    * Automatically resizes width/height to match the largest image.
</details>

### 📄 Docs & Utils
<details>
<summary><strong>Paste to File (PASTE2FILE.bat)</strong></summary>

* **What it does:** Grabs whatever text is in your clipboard and saves it to a `.txt` file in the current folder.
* **Usage:** Run it inside the folder where you want the file (via Right Click background).
</details>

<details>
<summary><strong>PDF OCR Enabler (OCRPDF.bat)</strong></summary>

* **What it does:** Adds a selectable text layer to scanned PDFs.
* **Requirement:** Requires Python and `pip install ocrmypdf`.
* **Usage:** Send PDF. Wait for it to finish.
</details>

<details>
<summary><strong>Comic Converter (COMIC2PDF.bat)</strong></summary>

* **What it does:** Converts Comic Books (.CBR/.CBZ) to PDF and vice-versa.
* **Usage:** Send file. It automatically detects direction (Archive -> PDF or PDF -> Archive).
</details>

---

## 📦 Requirements

These scripts rely on command-line tools. You need to have these added to your Windows **PATH**.

* **[FFmpeg](https://ffmpeg.org/download.html)** (Essential for all Video/Audio tools)
* **[ImageMagick](https://imagemagick.org/script/download.php)** (Essential for Image/PDF tools)
* **[7-Zip](https://www.7-zip.org/)** (Required for COMIC2PDF)
* **Python** + `pip install ocrmypdf` (Only for OCRPDF.bat)
* **[MediaInfo](https://mediaarea.net/en/MediaInfo/Download/Windows)** (Recommended for accurate FPS detection in animations)

## 📥 Installation

Download the latest Release, unzip it to a safe folder (e.g., `C:\Tools\ZhiroQuickTools`). Then choose your method:

### Method 1: Easy Context Menu (Recommended)
This is how I use them. It allows for a cleaner menu with custom icons (included in the repo).
1.  [Download](https://www.sordum.org/downloads/?easy-context-menu) and open **Easy Context Menu**.
2.  Open the **List Editor** (Mouse icon).
3.  Drag and drop the `.bat` files into the desired menu (e.g., "Context Menu").
4.  Assign the included icons if you want to be fancy.
5.  I leave the silent scripts outside the submenu for quicker access (VID2x264.bat,extract320.bat on files, paste2file.bat on explorer)
6.  Save changes.

![My Custom Context Menu](mymenu.png)
*(This is how my setup looks using the icons included in the repo)*

### Method 2: "SendTo" Folder (Native)
1.  Press `Win + R` and type `shell:sendto`.
2.  Create shortcuts of the `.bat` files you want to use inside that folder.
3.  **Usage:** Right Click any file > **Send to** > Select the script.

### Method 3: Any ther way you'd like to (registry, other apps, etc)

## 🗺️ Roadmap (Planned Features)

* **Simple Muxer:** A tool to quickly mux audio and video streams together.
* **Frames2Vid:** The inverse of FRAMES4ALL (reconstruct a video file from a folder of images).
* **Self-Updater:** A native way to update the suite directly from a script without re-downloading the zip.
  
## 🔄 Updating
Just download the new version and replace the `.bat` files in your tools folder.

---
*Made for personal use, shared for convenience.*
