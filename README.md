# Archiver
Archiver is a modern, lightweight, and high-performance macOS utility designed for seamless file compression and extraction. Built with SwiftUI and optimized for macOS 14+, it provides a clean, native experience for managing various archive formats while specifically addressing common issues like garbled character encoding in CJK (Chinese, Japanese, Korean) filenames.
+2

## 🚀 Features
### Multi-Format Support: 
Handles a wide array of formats including ZIP, TAR, GZ, BZ2, XZ, 7Z, and RAR.


### Smart CJK Decoding: 
Automatically detects and fixes garbled filenames caused by non-UTF-8 encodings (e.g., GBK, Big5, Shift-JIS) in ZIP and TAR archives.


### Intuitive UI:

#### Drag & Drop: 
Simply drop archives onto the interface to start browsing or extracting.


#### Advanced Table View: 
View file details, compression ratios, and modification dates with ease.


#### Sidebar Statistics: 
Get instant insights into file type breakdowns and overall compression efficiency.


#### Fast Operations: 
Utilizes asynchronous processing (actor-based ArchiveService) to keep the UI responsive during heavy tasks.


#### Native macOS Integration: 
Supports System Accents, Dark Mode, and standard Keyboard Shortcuts (Cmd+O for opening, Cmd+Shift+N for compressing).


## 🛠 Tech Stack
Language: Swift 

Framework: SwiftUI (using the @Observable macro) 

Libraries:

ZIPFoundation: For robust ZIP manipulation.

Foundation: For file management and process execution (tar via Process).


Architecture: Model-View-ViewModel 

## 📖 Usage
#### Opening an Archive

You can open an archive by clicking the "Open Archive" button, using the Cmd+O shortcut, or simply dragging a file into the application window.


#### Extracting Files

Once an archive is loaded, click "Extract All..." in the sidebar or toolbar. You can monitor real-time progress through a dedicated overlay.


#### Creating Archives

Click "Compress Files" to select multiple files or folders. The app will package them into a high-quality ZIP archive.


## 🧩 Key Logic: Encoding Fix
Standard ZIP files often use CP437 encoding for filenames if the UTF-8 flag isn't set, leading to "mojibake" (garbled text) for CJK users. Archiver implements a fallback mechanism that:

Detects CP437 artifacts (like box-drawing characters).

Re-encodes the raw bytes.

Attempts to decode using UTF-8, GB18030, Big5, or Shift-JIS to recover the original names.