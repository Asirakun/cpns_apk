import React from 'react';
import {Composition} from 'remotion';
import {CpnsIntro} from './CpnsIntro';

export const DURATION = 200; // 6,7 detik @30fps

export const RemotionRoot: React.FC = () => (
  <>
    {/* Vertikal 9:16 (Reels / TikTok / splash) */}
    <Composition
      id="CpnsIntro"
      component={CpnsIntro}
      durationInFrames={DURATION}
      fps={30}
      width={1080}
      height={1920}
    />
    {/* Horizontal 16:9 (YouTube / presentasi) */}
    <Composition
      id="CpnsIntroWide"
      component={CpnsIntro}
      durationInFrames={DURATION}
      fps={30}
      width={1920}
      height={1080}
    />
  </>
);
