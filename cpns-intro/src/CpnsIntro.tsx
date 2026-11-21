import React from 'react';
import {
  AbsoluteFill,
  Audio,
  Sequence,
  staticFile,
  Easing,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {loadFont} from '@remotion/google-fonts/PlusJakartaSans';
import {BookImages, BOOK_W, BOOK_H} from './BookImages';

const {fontFamily} = loadFont('normal', {
  weights: ['500', '800'],
  subsets: ['latin'],
});

const GOLD = '#f6b92b';

// Sound effect (dibuat oleh tools/make_sfx.py). from = frame mulai, vol = 0..1
const SFX = [
  {file: 'book-appear.wav', from: 6, vol: 1},
  {file: 'page-open.wav', from: 52, vol: 1},
  {file: 'road-draw.wav', from: 90, vol: 1},
  {file: 'flag-pop.wav', from: 116, vol: 1},
  {file: 'title-chime.wav', from: 126, vol: 1},
  {file: 'sparkle-end.wav', from: 150, vol: 1},
  {file: 'pad.wav', from: 100, vol: 1},
];
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export const CpnsIntro: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps, width, height} = useVideoConfig();

  // Ukuran buku menyesuaikan rasio video (9:16 atau 16:9)
  const bookW = Math.min(width * 0.72, height * 0.5 * (BOOK_W / BOOK_H));
  const bookH = bookW * (BOOK_H / BOOK_W);
  const sc = bookW / BOOK_W;

  // --- Timeline (30 fps) ---
  // 0-8     : layar kosong
  // 8-35    : buku tertutup muncul
  // 52-94   : buku terbuka
  // 90-122  : jalan tergambar
  // 116+    : bendera muncul
  // 126-172 : judul, tagline, garis emas
  const appear = spring({
    frame: frame - 8,
    fps,
    config: {damping: 16, stiffness: 90, mass: 0.9},
  });
  const appearOp = interpolate(frame, [8, 28], [0, 1], clamp);

  const openP = interpolate(frame, [52, 94], [0, 1], {
    ...clamp,
    easing: Easing.inOut(Easing.cubic),
  });
  
  const roadP = interpolate(frame, [90, 122], [0, 1], {
    ...clamp,
    easing: Easing.out(Easing.cubic),
  });

  const flagP = spring({
    frame: frame - 116,
    fps,
    config: {damping: 9, stiffness: 140, mass: 0.6},
  });
  const wave =
    frame > 116
      ? Math.sin((frame - 116) / 5) * 3.5 * Math.min(1, (frame - 116) / 20)
      : 0;

  const bookScale =
    interpolate(appear, [0, 1], [0.72, 1]) * 1;
  const bookY = (1 - appear) * 50 + Math.sin(frame / 18) * 3;

  const ease = Easing.out(Easing.cubic);
  const titleP = interpolate(frame, [126, 150], [0, 1], {...clamp, easing: ease});
  const tagP = interpolate(frame, [138, 162], [0, 1], {...clamp, easing: ease});
  const lineP = interpolate(frame, [150, 172], [0, 1], {...clamp, easing: ease});

  const ringsOp = interpolate(frame, [0, 45], [0, 1], clamp);
  const ringsScale = interpolate(frame, [0, 60], [0.9, 1], {...clamp, easing: ease});

  return (
    <AbsoluteFill
      style={{
        background:
          'radial-gradient(circle at 50% 42%, #0e2f57 0%, #0a2240 55%, #071a33 100%)',
        fontFamily,
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {SFX.map((x) => (
        <Sequence key={x.file} from={x.from}>
          <Audio src={staticFile(`sfx/${x.file}`)} volume={x.vol} />
        </Sequence>
      ))}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          transform: 'translateY(-4%)',
        }}
      >
        <div style={{position: 'relative', width: bookW, height: bookH}}>
          {/* lingkaran konsentris di belakang buku */}
          <div
            style={{
              position: 'absolute',
              left: '50%',
              top: '48%',
              width: bookW * 2.4,
              height: bookW * 2.4,
              transform: `translate(-50%, -50%) scale(${ringsScale})`,
              opacity: ringsOp,
            }}
          >
            <svg viewBox="-800 -800 1600 1600" width="100%" height="100%">
              {[1, 2, 3, 4, 5, 6, 7].map((i) => (
                <circle
                  key={i}
                  r={i * 110}
                  fill="none"
                  stroke="#fff"
                  strokeWidth={2}
                  opacity={Math.max(0.01, 0.07 - i * 0.009)}
                />
              ))}
            </svg>
          </div>

          <div
            style={{
              position: 'absolute',
              inset: 0,
              opacity: appearOp,
              transform: `translateY(${bookY}px) scale(${bookScale})`,
            }}
          >
            <div style={{width: BOOK_W, height: BOOK_H, transform: `scale(${sc})`, transformOrigin: '0 0'}}>
              <BookImages openP={openP} roadP={roadP} flagP={flagP} wave={wave} />
            </div>
          </div>
        </div>

        <div
          style={{
            marginTop: bookW * 0.05,
            fontSize: bookW * 0.115,
            fontWeight: 800,
            color: '#fff',
            letterSpacing: -1,
            opacity: titleP,
            transform: `translateY(${(1 - titleP) * 30}px)`,
          }}
        >
          CPNS Journey
        </div>
        <div
          style={{
            marginTop: bookW * 0.02,
            fontSize: bookW * 0.048,
            fontWeight: 500,
            color: 'rgba(255,255,255,0.72)',
            letterSpacing: 1.5,
            opacity: tagP,
            transform: `translateY(${(1 - tagP) * 20}px)`,
          }}
        >
          Persiapan yang terarah
        </div>
        <div
          style={{
            marginTop: bookW * 0.045,
            width: bookW * 0.12,
            height: Math.max(3, bookW * 0.006),
            borderRadius: 4,
            background: GOLD,
            transform: `scaleX(${lineP})`,
          }}
        />
      </div>
    </AbsoluteFill>
  );
};
