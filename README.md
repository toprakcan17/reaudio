# Audiobook-tts (no other better name exists i guess)

Audiobook-tts is a basic Flutter app for converting .epub and .pdf files to audiobooks via TTS (text to speech generation). 
The app can be also used as an e-reader app, as it also has text support, without playing any audio. 

## Features
  - Supports .epub (.pdf support will be implemented later)
  - Can pull up e-books from archive.org's massive 20+ Million public domain books archive
  - Converts e-pub to audio with TTS (online TTS APIs (Elevenlabs, Gemini TTS, OpenAI TTS, etc...) support will be implemented later)
## Dependencies
  + epubx: 4.0.0
  + file_picker: ^8.1.2
  + path_provider: ^2.1.3
  + flutter_tts: ^4.2.0
  + just_audio: ^0.9.40
  + permission_handler: ^11.3.2
  + sqflite: ^2.4.2
  + path: ^1.9.1
  + shared_preferences: ^2.5.4
  + http: ^1.6.0
  + html: ^0.15.6

## Build from source
### Requirements
+ Flutter SDK
### Steps to build
`git clone https://github.com/toprakcan17/audiobook-tts.git`

`cd audiobook-tts`

`flutter pub get`

`flutter build`
