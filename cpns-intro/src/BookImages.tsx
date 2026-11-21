import React from 'react';
import {Img, staticFile} from 'remotion';

// Semua posisi dalam piksel lokal buku terbuka (585 x 334).
export const BOOK_W = 585;
export const BOOK_H = 334;

const clamp = (x: number) => Math.min(1, Math.max(0, x));
const easeOut = (t: number) => 1 - Math.pow(1 - t, 3);

type Props = {openP: number; roadP: number; flagP: number; wave: number};

export const BookImages: React.FC<Props> = ({openP, roadP, flagP, wave}) => {
  const rev = easeOut(clamp((openP - 0.15) / 0.7)); // pembukaan halaman dari punggung buku
  const closedOp = 1 - clamp((openP - 0.2) / 0.45);
  const closedScale = 1 + 0.08 * openP;
  const glow = Math.sin(clamp(openP) * Math.PI) * 0.45;
  const roadMask = `linear-gradient(to top, #000 ${roadP * 100}%, transparent ${roadP * 100 + 10}%)`;

  return (
    <div style={{position: 'relative', width: BOOK_W, height: BOOK_H}}>
      {/* cahaya saat buku terbuka */}
      <div
        style={{
          position: 'absolute',
          left: -120,
          top: -120,
          width: BOOK_W + 240,
          height: BOOK_H + 240,
          background:
            'radial-gradient(closest-side, rgba(246,185,43,0.9), rgba(246,185,43,0) 100%)',
          opacity: glow * 0.6 + openP * 0.12,
        }}
      />
      {/* bayangan */}
      <div
        style={{
          position: 'absolute',
          left: 40,
          top: BOOK_H - 30,
          width: BOOK_W - 80,
          height: 44,
          background:
            'radial-gradient(closest-side, rgba(0,0,0,0.38), rgba(0,0,0,0))',
        }}
      />

      {/* buku terbuka: terungkap dari punggung ke kedua sisi */}
      <Img
        src={staticFile('book-open.png')}
        style={{
          position: 'absolute',
          left: 0,
          top: 0,
          width: BOOK_W,
          height: BOOK_H,
          clipPath: `inset(0 ${(1 - rev) * 50}% 0 ${(1 - rev) * 50}%)`,
          transform: `scaleX(${0.8 + 0.2 * rev})`,
          opacity: rev > 0 ? 1 : 0,
        }}
      />

      {/* buku tertutup: memudar dan sedikit membesar saat terbuka */}
      <Img
        src={staticFile('book-closed.png')}
        style={{
          position: 'absolute',
          left: (BOOK_W - 354) / 2,
          top: 15,
          width: 354,
          height: 313,
          opacity: closedOp,
          transform: `scale(${closedScale})`,
          transformOrigin: '50% 90%',
        }}
      />

      {/* jalan tergambar dari bawah ke atas */}
      <div
        style={{
          position: 'absolute',
          left: 187,
          top: 3,
          width: 223,
          height: 239,
          WebkitMaskImage: roadMask,
          maskImage: roadMask,
          opacity: roadP > 0 ? 1 : 0,
        }}
      >
        <Img src={staticFile('road-rot.png')} style={{width: '100%', height: '100%'}} />
      </div>

      {/* bendera */}
      <Img
        src={staticFile('flag.png')}
        style={{
          position: 'absolute',
          left: 289,
          top: -84,
          width: 76,
          height: 101,
          opacity: Math.min(1, flagP * 3),
          transform: `scale(${flagP}) rotate(${wave * 0.6}deg)`,
          transformOrigin: '12% 100%',
        }}
      />
    </div>
  );
};
