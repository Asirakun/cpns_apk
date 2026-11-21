import timing from './elevenlabs-timing.json';
import {monotone} from './engine/lib';
export const FPS=60;
export const DURATION=121.33333333333333;
export const NARRATION_SOURCE='audio/elevenlabs-final.wav';
export const audioTiming=timing;
const clock=monotone([...timing.map(t=>[t.slotStart,t.baseStart]),[121.33333333333333,120]]);
export const baseTime=(seconds:number)=>clock(Math.max(0,Math.min(121.33333333333333,seconds)));
