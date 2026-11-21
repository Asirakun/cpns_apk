// Adapted MIT paper mechanisms from Lemo-Opuscar. Animation is a pure function of the Remotion frame.
import * as THREE from 'three';
import {makeBook,texOf,PG} from './book.js';
import {cv,finishCut,paperFill,INK} from './paper.js';
import {cutMesh,blobShadow} from './cutmesh.js';
import {seg,ss,eio,back,lerp,mulberry,track} from './lib.js';
import {scenes,DUR,turns} from '../story.js';
export function createWorld(images){
const C={navy:'#0b2943',blue:'#236d9d',light:'#acd8ed',cream:'#fff2d8',gold:'#f6c64c',ink:'#3a2a24',green:'#4e937e',rose:'#c77866'};
function rr(x,a,b,w,h,r,fill,stroke=INK,lw=4){x.beginPath();x.roundRect(a,b,w,h,r);if(fill){x.fillStyle=fill;x.fill()}if(stroke){x.lineWidth=lw;x.strokeStyle=stroke;x.stroke()}}
function txt(x,t,a,b,size=40,col=C.navy,align='center',weight=700){x.font=`${weight} ${size}px Jakarta`;x.fillStyle=col;x.textAlign=align;x.textBaseline='middle';x.fillText(t,a,b)}
function art(w,h,fn,border=10){const c=cv(w,h);fn(c.getContext('2d'),w,h);return finishCut(c,border,{grainA:.42})}
function item(c,w,h){return cutMesh({c,w,h,ax:.5,ay:1})}
function plaque(text,w=620,h=220,color=C.cream,size=65){return art(w,h,(x)=>{rr(x,22,22,w-44,h-44,25,color,INK,6);txt(x,text,w/2,h/2,size)})}
function imageArt(key,w=500,h=500){return art(w,h,(x)=>{const i=images[key],s=Math.min((w-40)/i.width,(h-40)/i.height);x.drawImage(i,(w-i.width*s)/2,(h-i.height*s)/2,i.width*s,i.height*s)})}
function deck(label,color,icon){return art(600,540,x=>{rr(x,22,22,556,496,34,C.cream,INK,6);rr(x,44,44,512,280,25,color,null);if(icon){const i=images[icon];x.drawImage(i,180,53,240,240)}txt(x,label,300,399,69);rr(x,150,464,300,9,4,C.gold,null)})}
function check(x,a,b,s,color=C.green){x.strokeStyle=color;x.lineWidth=s*.17;x.lineCap='round';x.lineJoin='round';x.beginPath();x.moveTo(a,b+s*.5);x.lineTo(a+s*.36,b+s*.86);x.lineTo(a+s,b);x.stroke()}

const scene=new THREE.Group();
scene.add(new THREE.HemisphereLight('#f5e9d4','#716454',2.05));
const key=new THREE.DirectionalLight('#fff0d9',3.2);key.position.set(-.6,1.3,.65);key.castShadow=true;key.shadow.mapSize.set(2048,2048);Object.assign(key.shadow.camera,{left:-.85,right:.85,top:.8,bottom:-.5,near:.05,far:4});key.shadow.bias=-.00006;key.shadow.normalBias=.0004;key.shadow.radius=3;scene.add(key);
const fill=new THREE.DirectionalLight('#c1dff3',.7);fill.position.set(.7,.5,-.2);scene.add(fill);

// Real-scale wood surface: layered grain, pores, knots, and long satin highlights.
const wood=cv(2048,1024),wx=wood.getContext('2d'),R=mulberry(79);wx.fillStyle='#b99b7d';wx.fillRect(0,0,2048,1024);
for(let j=0;j<7500;j++){let y=R()*1024,h=R()*1.5+.2;wx.strokeStyle=`rgba(${R()<.5?'65,35,20':'231,199,158'},${.02+R()*.09})`;wx.lineWidth=h;wx.beginPath();for(let k=0;k<=32;k++){let x=k*64,yy=y+Math.sin(x*.003+y*.03)*(1+R()*3);k?wx.lineTo(x,yy):wx.moveTo(x,yy)}wx.stroke()}
for(let j=0;j<60;j++){wx.fillStyle='rgba(64,35,23,.03)';wx.beginPath();wx.ellipse(R()*2048,R()*1024,20+R()*180,1+R()*4,0,0,Math.PI*2);wx.fill()}
const wt=texOf(wood);wt.wrapS=wt.wrapT=THREE.RepeatWrapping;wt.repeat.set(2,2);const desk=new THREE.Mesh(new THREE.BoxGeometry(3,.055,2),new THREE.MeshStandardMaterial({map:wt,roughness:.63}));desk.position.set(0,-.035,.0);desk.receiveShadow=true;scene.add(desk);
function mesh(geo,col,pos,roughness=.7){const m=new THREE.Mesh(geo,new THREE.MeshStandardMaterial({color:col,roughness}));m.position.set(...pos);m.castShadow=m.receiveShadow=true;scene.add(m);return m}
// A practical desk lamp, ceramic mug and pencil are still throughout the film.
mesh(new THREE.CylinderGeometry(.055,.063,.012,48),'#254153',[-.48,.006,-.11],.35);mesh(new THREE.CylinderGeometry(.005,.005,.39,16),'#b69d72',[-.48,.2,-.13],.4);
const shade=mesh(new THREE.CylinderGeometry(.027,.087,.08,48,1,true),'#315365',[-.48,.405,-.13],.38);shade.material.side=THREE.DoubleSide;
const lampLight=new THREE.PointLight('#ffd894',.065,.85,2);lampLight.position.set(-.48,.37,-.13);scene.add(lampLight);
mesh(new THREE.CylinderGeometry(.035,.03,.075,48),'#f1e6d5',[.46,.038,-.08],.25);const coffee=mesh(new THREE.CircleGeometry(.031,48),'#56382a',[.46,.076,-.08]);coffee.rotation.x=-Math.PI/2;
const handle=mesh(new THREE.TorusGeometry(.02,.006,10,32),'#e9decf',[.498,.041,-.08],.25);handle.rotation.y=Math.PI/2;
const pencil=mesh(new THREE.CylinderGeometry(.003,.003,.17,6),C.gold,[-.35,.005,.28]);pencil.rotation.z=Math.PI/2;pencil.rotation.y=.35;
const wall=mesh(new THREE.PlaneGeometry(6,4),'#b8b09f',[0,.9,-1]);

// Custom cover: no demo lettering or characters.
const cover=cv(2048,1396),cx=cover.getContext('2d');paperFill(cx,2048,1396,C.navy,21,.1);cx.strokeStyle=C.gold;cx.lineWidth=9;cx.strokeRect(85,85,1878,1226);cx.drawImage(images.logo,790,195,468,468);txt(cx,'CPNS',1024,790,190,C.cream);txt(cx,'Journey',1024,1000,190,C.gold);txt(cx,'Satu langkah lebih siap.',1024,1200,58,C.cream);
const metal=cv(32,32);metal.getContext('2d').fillStyle='#00e000';metal.getContext('2d').fillRect(0,0,32,32);
const book=makeBook({c:cover,m:metal});book.root.position.y=-PG+.001;scene.add(book.root);book.setOpen(Math.PI/2);
const palettes=[['#e8d4ae','#f6ecd6'],['#b8d9d6','#f4e9d0'],['#b3cee4','#f0e4cb'],['#d5dcb9','#f5ead0']];const backs=[],grounds=[];
for(let k=0;k<4;k++){const bc=cv(2048,1396),x=bc.getContext('2d');paperFill(x,2048,1396,palettes[k][0],k+1,.08);x.strokeStyle='rgba(255,255,255,.26)';x.lineWidth=4;for(let j=0;j<4;j++){x.beginPath();x.arc(1750,310,200+j*135,0,Math.PI*2);x.stroke()}txt(x,['SATU LANGKAH','BELAJAR','BERLATIH','JOURNEY'][k],1024,190,94,C.navy);txt(x,['Mulai dari yang kecil.','Sedikit hari ini. Lebih siap esok.','Kenali ritme. Temukan fokus.','Persiapan yang lebih terarah.'][k],1024,330,42,C.navy);const gc=cv(2048,1396),g=gc.getContext('2d');paperFill(g,2048,1396,palettes[k][1],k+22,.07);g.strokeStyle='rgba(100,83,54,.05)';g.lineWidth=2;for(let y=50;y<1396;y+=68){g.beginPath();g.moveTo(0,y);g.lineTo(2048,y);g.stroke()}g.strokeStyle=C.gold;g.lineWidth=56;g.lineCap='round';g.beginPath();g.moveTo(290,1396);g.bezierCurveTo(200,700,1800,1100,1500,450);g.stroke();backs.push(texOf(bc));grounds.push(texOf(gc));}

// The phone is a physical object, using original app captures.
const phone=new THREE.Group();phone.position.set(.31,.01,.055);phone.rotation.y=-.18;scene.add(phone);
const phoneBody=new THREE.Mesh(new THREE.BoxGeometry(.081,.181,.009,1,1,1),new THREE.MeshStandardMaterial({color:'#17222b',roughness:.24,metalness:.3}));phoneBody.position.y=.09;phoneBody.castShadow=true;phone.add(phoneBody);
const phoneTextures={};for(const n of ['home','tryouts','priorities','preparation']){const t=new THREE.Texture(images[n]);t.colorSpace=THREE.SRGBColorSpace;t.needsUpdate=true;phoneTextures[n]=t}
const phoneScreen=new THREE.Mesh(new THREE.PlaneGeometry(.073,.168),new THREE.MeshBasicMaterial({map:phoneTextures.home}));phoneScreen.position.set(0,.09,.0048);phone.add(phoneScreen);
const earpiece=new THREE.Mesh(new THREE.BoxGeometry(.018,.002,.001),new THREE.MeshStandardMaterial({color:'#101820'}));earpiece.position.set(0,.177,.0055);phone.add(earpiece);

const pops=[];function pop(c,w,h,x,y,z,start,end=121,opts={}){const pivot=new THREE.Group(),card=item(c,w,h);pivot.position.set(x,y,z);pivot.add(card);book.stage.add(pivot);const a={pivot,card,start,end,x,y,z,...opts};pops.push(a);return a}
function sign(text,x,z,start,end=121,w=.105,color=C.cream,size=65){return pop(plaque(text,620,220,color,size),w,w*220/620,x,0,z,start,end)}
function flatImage(key,x,z,start,end,w=.06){return pop(imageArt(key),w,w,x,0,z,start,end)}

// First spread: competing piles, then the pull-tab opens a route.
const pile=[];for(let j=0;j<3;j++){const p=pop(deck(['Materi','Latihan','Berkas'][j],[C.light,'#e9d28d','#b8ceb6'][j],['book','target','checklist'][j]),.105,.094,-.13+j*.13,0,.09,0,16.5,{spread:0});pile.push(p)}
const startTab=sign('Mulai →',-.02,.22,0,16.5,.105,C.gold,76);
const brand=sign('CPNS Journey',0,.12,8.3,16.5,.255,C.cream,73);

// Second spread: hinged subjects, saved lesson, spaced-repetition calendar.
const subjects=[];for(let j=0;j<3;j++)subjects.push(pop(deck(['TWK','TIU','TKP'][j],[C.light,'#f2d47b','#b8d4b5'][j],['book','target','welcome'][j]),.095,.086,-.13+j*.13,0,.07,18.5+j*.22,38.5));
const mark=pop(plaque('TERSIMPAN',550,180,C.gold,53),.095,.031,.135,.095,.11,24.5,38.5);
const calendar=[];for(let j=0;j<3;j++)calendar.push(pop(art(420,400,x=>{rr(x,20,20,380,360,30,C.cream,INK,6);rr(x,20,20,380,83,28,C.navy,null);txt(x,'ULANGI',210,63,30,C.cream);txt(x,String([1,3,7][j]),210,221,140);txt(x,'hari lagi',210,331,36)}),.061,.058,-.06+j*.077,0,.165,29+j*.38,38.5));
const again=sign('Pelajari lagi',.025,.265,30.5,38.5,.13,C.cream,64);

// Third spread: the CAT console, a flag and the review mechanism.
const exam=pop(art(1100,680,x=>{rr(x,22,22,1056,636,38,C.cream,INK,7);rr(x,45,45,1010,107,20,C.navy,null);txt(x,'SIMULASI CAT',550,100,61,C.cream);txt(x,'110 soal',310,230,74);txt(x,'100 menit',770,230,74);txt(x,'Latih ketelitian dan pembagian waktu.',550,335,38);for(let j=0;j<4;j++){rr(x,105,405+j*48,36,32,9,j===1?C.gold:null,C.blue,4);rr(x,166,414+j*48,690-j*60,12,6,j===1?C.blue:'#b1c4c8',null)}}),.26,.161,.025,0,.065,40.5,61.8);
const navigator=pop(art(1000,180,x=>{for(let j=0;j<10;j++){rr(x,12+j*98,16,84,141,15,j===3?C.gold:j<3?C.green:C.cream,INK,4);txt(x,String(j+1),54+j*98,88,50,j<3?C.cream:C.navy)}}),.25,.045,.025,0,.2,43,61.8);
const flag=pop(art(500,320,x=>{x.strokeStyle=INK;x.lineWidth=14;x.beginPath();x.moveTo(48,300);x.lineTo(48,38);x.stroke();x.beginPath();x.moveTo(53,42);x.lineTo(440,42);x.lineTo(390,143);x.lineTo(440,238);x.lineTo(53,238);x.closePath();x.fillStyle=C.gold;x.fill();x.lineWidth=6;x.stroke();txt(x,'RAGU?',240,143,65)}),.07,.045,.158,.125,.10,51,61.8);
const saved=sign('Tersimpan di perangkat',.03,.255,55,61.8,.24,C.cream,48);
const bars=[];for(let j=0;j<3;j++){bars.push(pop(art(320,600,x=>{rr(x,22,20,276,560,24,[C.blue,C.gold,C.green][j],INK,6);txt(x,['TWK','TIU','TKP'][j],160,480,68,j===1?C.navy:C.cream)}),.055,[.09,.135,.11][j],-.075+j*.08,0,.08,63+j*.24,72.5))}
const example=sign('Contoh latihan',.03,.18,62.7,72.5,.16,C.cream,58);
const review=sign('Fokus berikutnya →',.03,.235,67,72.5,.21,C.gold,56);

// Fourth spread: a map, not a promise that the stages are complete.
const milestones=[];for(let j=0;j<12;j++){const x=-.15+(j%6)*.06,z=.07+Math.floor(j/6)*.085;milestones.push(sign(`S${String(j).padStart(2,'0')}`,x,z,74.8+j*.13,85.9,.052,j===2?C.gold:C.cream,66))}
const active=sign('Tahap aktif',-.03,.23,78,85.9,.14,C.gold,61);
const checklist=pop(art(820,780,x=>{rr(x,22,22,776,736,30,C.cream,INK,7);rr(x,60,55,700,130,20,C.blue,null);txt(x,'CHECKLIST BERKAS',410,120,57,C.cream);for(let j=0;j<3;j++){rr(x,88,257+j*140,67,67,12,null,C.blue,5);txt(x,['Berkas pribadi','Catatan persiapan','Agenda berikutnya'][j],195,290+j*140,40,C.navy,'left',600)}check(x,96,255,48);txt(x,'Status dan catatan pribadi',410,710,35,C.blue)}),.19,.181,.04,0,.06,86.3,107.7);
const agenda=pop(art(480,450,x=>{rr(x,20,20,440,410,30,C.cream,INK,6);rr(x,22,22,436,92,26,C.gold,null);txt(x,'AGENDA',240,70,50);for(let j=0;j<12;j++){let xx=80+(j%4)*105,yy=175+Math.floor(j/4)*85;rr(x,xx-28,yy-26,56,53,10,j===6?C.blue:'#e9e1ce',null);if(j===6)check(x,xx-18,yy-18,31,C.cream)}}),.074,.069,-.115,0,.17,89,107.7);
const offline=sign('BISA OFFLINE',.015,.24,99,107.7,.21,C.gold,69);
const bookmark=pop(plaque('Lanjut besok',600,180,C.gold,63),.14,.042,.07,0,.19,109.4,121);

// Original paper actor: separate head, arms, shirt and trousers on one cut card.
const actorCanvas=cv(480,780),ax=actorCanvas.getContext('2d');const actor=item(actorCanvas,.054,.088);book.stage.add(actor);const actorShadow=blobShadow(.018,.22);book.stage.add(actorShadow);let lastPose='';
function actorDraw(t,mood,walk=0){t=Math.floor(t*24)/24;const pose=[t,mood,Math.round(walk*8)].join(':');if(pose===lastPose)return;lastPose=pose;ax.clearRect(0,0,480,780);const bob=Math.sin(walk)*8;
ax.save();ax.translate(0,bob);ax.lineJoin='round';ax.lineCap='round';
// Border silhouettes are generated from this drawing, including the moving arms.
function shape(fn,col,lw=12){ax.beginPath();fn();ax.fillStyle=col;ax.fill();ax.strokeStyle=INK;ax.lineWidth=lw;ax.stroke()}
const leg=Math.sin(walk)*12;shape(()=>{ax.moveTo(155,555);ax.lineTo(158+leg,716);ax.lineTo(220+leg,716);ax.lineTo(241,568)},'#334658');shape(()=>{ax.moveTo(239,565);ax.lineTo(255-leg,716);ax.lineTo(316-leg,716);ax.lineTo(324,552)},'#334658');rr(ax,134+leg,699,104,37,17,INK,null);rr(ax,243-leg,699,101,37,17,INK,null);
shape(()=>{ax.moveTo(171,349);ax.quadraticCurveTo(92,370,81,507);ax.quadraticCurveTo(85,535,117,524);ax.lineTo(170,425)},C.blue);
const armUp=mood==='happy'||mood==='point';shape(()=>{ax.moveTo(307,350);ax.quadraticCurveTo(363,350,armUp?397:383,armUp?262:490);ax.quadraticCurveTo(413,armUp?229:523,430,armUp?265:503);ax.lineTo(355,armUp?397:550);ax.lineTo(302,430)},C.blue);
shape(()=>{ax.moveTo(170,342);ax.quadraticCurveTo(235,322,308,346);ax.lineTo(332,575);ax.quadraticCurveTo(241,605,146,574);ax.closePath()},C.blue);
shape(()=>{ax.moveTo(212,332);ax.lineTo(211,374);ax.quadraticCurveTo(241,402,271,372);ax.lineTo(270,330)},'#e2a677',8);
shape(()=>ax.ellipse(239,225,104,125,0,0,Math.PI*2),'#f3c595');
shape(()=>{ax.moveTo(137,237);ax.quadraticCurveTo(102,87,236,87);ax.quadraticCurveTo(370,72,347,226);ax.lineTo(319,210);ax.lineTo(302,155);ax.quadraticCurveTo(236,197,163,154);ax.lineTo(160,229);ax.closePath()},'#253f51');
ax.fillStyle=INK;const blink=Math.sin(t*1.71)> .991;for(const x of [205,280]){ax.beginPath();ax.ellipse(x,233,10,blink?2:14,0,0,Math.PI*2);ax.fill()}
ax.strokeStyle=INK;ax.lineWidth=7;ax.beginPath();if(mood==='confused'){ax.moveTo(218,290);ax.quadraticCurveTo(243,273,264,287)}else{ax.moveTo(213,279);ax.quadraticCurveTo(241,309,271,277)}ax.stroke();ax.fillStyle='rgba(210,106,85,.33)';for(const x of [179,306]){ax.beginPath();ax.ellipse(x,268,17,9,0,0,Math.PI*2);ax.fill()}
if(mood==='confused'){txt(ax,'?',383,112,91,C.gold)}ax.restore();const finished=finishCut(actorCanvas,9,{grainA:.3});actor.userData.tex.image=finished;actor.userData.tex.needsUpdate=true;}

const blendBackCanvas=cv(1024,700),blendGroundCanvas=cv(1024,700),blendBack=texOf(blendBackCanvas),blendGround=texOf(blendGroundCanvas);
function paintBlend(canvas,a,b,u){const ctx=canvas.getContext('2d');ctx.globalAlpha=1;ctx.drawImage(a.image,0,0,canvas.width,canvas.height);ctx.globalAlpha=u;ctx.drawImage(b.image,0,0,canvas.width,canvas.height);ctx.globalAlpha=1;}
function seek(t){t=Math.max(0,Math.min(120,t));let idx=scenes.findIndex(s=>t>=s.start&&t<s.end);if(idx<0)idx=11;const spread=t<18.7?0:t<40.7?1:t<74.7?2:3;book.groundMat.map=grounds[spread];book.backMat.map=backs[spread];book.setOpen(Math.PI/2*(1-eio(seg(t,111.4,115.3))));book.setLeaf(0);
for(let j=0;j<turns.length;j++){let u=seg(t,turns[j],turns[j]+2.2);if(u>0&&u<1){book.leafFront.material.map=grounds[j];book.leafFront.material.emissiveMap=grounds[j];book.leafBack.material.map=backs[j+1];book.leafBack.material.emissiveMap=backs[j+1];book.setLeaf(eio(u));const w=ss(u);paintBlend(blendBackCanvas,backs[j],backs[j+1],w);paintBlend(blendGroundCanvas,grounds[j],grounds[j+1],w);blendBack.needsUpdate=blendGround.needsUpdate=true;book.backMat.map=blendBack;book.groundMat.map=blendGround;}}
for(const p of pops){let rise=back(seg(t,p.start,p.start+.68),1.15),fall=1-ss(seg(t,p.end-.52,p.end));if(p.start===0)rise=1;let k=rise*fall;p.pivot.visible=k>.001;p.pivot.rotation.x=-Math.PI/2*(1-k);p.pivot.rotation.z=Math.sin(t*1.3+p.x*30)*.005*k;p.pivot.position.set(p.x,p.y,p.z);}again.pivot.visible=false;
for(let j=0;j<3;j++){pile[j].pivot.position.x=pile[j].x+[-.08,.02,.08][j]*eio(seg(t,8,10));pile[j].pivot.rotation.z=(j-1)*.09*(1-eio(seg(t,8,10)));}startTab.pivot.position.x=startTab.x+.06*eio(seg(t,8,9.4));
if(t>=62&&t<73)for(let j=0;j<bars.length;j++)bars[j].pivot.scale.y=1+Math.sin(t*1.2+j)*.015;
const mood=t<8?'confused':t<18||t>108?'happy':'point';let actorX=t<18?lerp(-.01,-.175,eio(seg(t,8,11))):-.177;let walk=t>8&&t<11?(t-8)*10:0;actor.position.set(actorX,Math.abs(Math.sin(walk))*.0012,.21);actor.visible=t<111;actorShadow.visible=actor.visible;actorShadow.position.set(actorX,.0006,.21);actorDraw(t,mood,walk);
bookmark.pivot.position.y=.007+ss(seg(t,112,115))*.007;bookmark.pivot.rotation.x=-Math.PI/2*ss(seg(t,110.4,111.3));bookmark.pivot.position.z=.28;
phoneScreen.material.map=phoneTextures[t<18?'home':t<40?'priorities':t<74?'tryouts':t<98?'preparation':'home'];
scene.updateMatrixWorld(true);}
return {scene,seek};
}
