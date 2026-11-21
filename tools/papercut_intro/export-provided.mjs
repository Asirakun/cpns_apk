import fs from 'node:fs';
import {spring,interpolate,Easing} from 'remotion';
const clamp={extrapolateLeft:'clamp',extrapolateRight:'clamp'};
const samples=[];
for(let frame=0;frame<200;frame++){
 const appear=spring({frame:frame-8,fps:30,config:{damping:16,stiffness:90,mass:.9}});
 samples.push({appear:interpolate(frame,[8,28],[0,1],clamp),scale:interpolate(appear,[0,1],[.72,1]),
 y:(1-appear)*50+Math.sin(frame/18)*3,
 open:interpolate(frame,[52,94],[0,1],{...clamp,easing:Easing.inOut(Easing.cubic)}),
 road:interpolate(frame,[90,122],[0,1],{...clamp,easing:Easing.out(Easing.cubic)}),
 flag:spring({frame:frame-116,fps:30,config:{damping:9,stiffness:140,mass:.6}}),
 wave:frame>116?Math.sin((frame-116)/5)*3.5*Math.min(1,(frame-116)/20):0,
 title:interpolate(frame,[126,150],[0,1],{...clamp,easing:Easing.out(Easing.cubic)}),
 tag:interpolate(frame,[138,162],[0,1],{...clamp,easing:Easing.out(Easing.cubic)}),
 line:interpolate(frame,[150,172],[0,1],{...clamp,easing:Easing.out(Easing.cubic)})});
}
fs.writeFileSync('../../assets/intro/provided-motion.json',JSON.stringify({fps:30,frames:200,durationMs:6667,samples})+'\n');
console.log('Exported original cpns-intro motion: 200 frames, 6.667 s. Background/rings omitted.');
