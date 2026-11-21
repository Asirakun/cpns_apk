# CPNS Journey - Intro (Remotion)
Aset gambar : public/ (book-closed, book-open, road-rot, flag)
Sound effect: public/sfx/*.wav (dibuat oleh `python tools/make_sfx.py`; edit skrip lalu jalankan ulang untuk mengubah suara)
Timing SFX  : konstanta SFX di src/CpnsIntro.tsx (from = frame mulai, vol = volume)

npm install | npm run dev | npm run render (9:16) | npm run render:wide (16:9)
Render laptop RTX 3050: pakai --gl=angle (sudah di script), turunkan --concurrency bila panas/RAM penuh.
