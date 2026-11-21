import React,{useEffect,useState}from'react';
import{AbsoluteFill,Audio,Composition,continueRender,delayRender,staticFile}from'remotion';
import{ThreeCanvas}from'@remotion/three';
import * as THREE from'three';
import{World}from'./World';import{Overlay}from'./Overlay';
import{DURATION,FPS,NARRATION_SOURCE}from'./timeline';
export const JourneyFilm:React.FC=()=>{
 const[handle]=useState(()=>delayRender('Loading the local CPNS artwork and font'));
 const[images,setImages]=useState<Record<string,HTMLImageElement>|null>(null);
 useEffect(()=>{let active=true;const artwork:Record<string,HTMLImageElement>={};(async()=>{const font=new FontFace('Jakarta',`url(${staticFile('PlusJakartaSans.ttf')})`,{weight:'100 900'});await font.load();document.fonts.add(font);await Promise.all(['logo','home','tryouts','priorities','preparation','welcome','book','checklist','target','route'].map(async name=>{const im=new Image();im.src=staticFile(name+'.png');await im.decode();artwork[name]=im}));if(active)setImages(artwork);continueRender(handle)})().catch(e=>{console.error(e);continueRender(handle)});return()=>{active=false};},[handle]);
 if(!images)return null;
 return <AbsoluteFill style={{background:'#d7c6b2'}}>
  <ThreeCanvas width={1920} height={1080} shadows camera={{fov:34,near:.004,far:20,position:[.045,.19,.56]}} gl={{antialias:true,alpha:false,powerPreference:'high-performance',preserveDrawingBuffer:true}} onCreated={({gl,scene})=>{gl.toneMapping=THREE.NeutralToneMapping;gl.outputColorSpace=THREE.SRGBColorSpace;gl.shadowMap.type=THREE.PCFSoftShadowMap;scene.background=new THREE.Color('#d7c6b2');scene.fog=new THREE.Fog('#d7c6b2',1.8,4.6)}}>
   <World images={images}/>
  </ThreeCanvas>
  <Overlay/>
  <Audio src={staticFile(NARRATION_SOURCE)}/>
 </AbsoluteFill>;
};
export const MyComposition=()=> <Composition id="CPNSJourney" component={JourneyFilm} width={1920} height={1080} fps={FPS} durationInFrames={Math.round(DURATION*FPS)}/>;
