# Video demo CPNS Journey

Video buku pop-up React Remotion + Three.js, 1080p 60fps, sekitar 121 detik. Kamera bergerak kontinu mengikuti fitur. Header putih dan label tahap telah dihapus. Narasi Indonesia: Bella (wanita), ElevenLabs Multilingual v2; subtitle mengikuti timestamp ucapan.

## Render pada Windows / RTX 3050

1. Pasang Node.js sesuai engines di remotion-video/package.json.
2. Dari folder ini, jalankan cd remotion-video lalu npm ci. Jalankan npx remotion browser ensure untuk menyiapkan Chrome, lalu kembali dengan cd .. . Arahkan TEMP/TMP ke disk D bila diperlukan.
3. Simpan FFmpeg di tools/ffmpeg.exe (unduh dari sumber FFmpeg yang Anda percayai).
4. Jalankan:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Render-RTX3050.ps1
```

Hasil: out/remotion-v2/CPNS_JOURNEY_REMOTION_1080p60.mp4. GPU NVIDIA RTX 3050 diverifikasi melalui ANGLE/D3D11; NVENC diwajibkan. Narasi siap render disertakan; render tidak memakai kredit ElevenLabs. MP4 final disimpan lokal dan tidak dimasukkan ke Git.

Untuk narasi baru, salin .env.example menjadi .env.local dan isi key pribadi, lalu node tools/elevenlabs.mjs generate dan node audio-v2.mjs. Proses ini menggunakan layanan/kredit ElevenLabs. Jangan commit key.

Kode mekanisme kertas diadaptasi dari [Lemo-Opuscar](https://github.com/lemomo-ai/lemo-opuscar), MIT; lisensi di vendor/. Three.js MIT. Plus Jakarta Sans OFL (remotion-video/public/FONT_LICENSE.txt). Logo dan screenshot berasal dari aplikasi ini. Musik dan foley disintesis lokal.
