import React from'react';import{Img,staticFile,useCurrentFrame,useVideoConfig}from'remotion';
import{scenes}from'./story';import{audioTiming,baseTime,DURATION}from'./timeline';
const smooth=(v:number)=>{const u=Math.min(1,Math.max(0,v));return u*u*(3-2*u)};
const ink='#15334a';
export const Overlay:React.FC=()=>{const frame=useCurrentFrame(),{fps}=useVideoConfig(),seconds=frame/fps,t=baseTime(seconds);const idx=Math.max(0,scenes.findIndex((s:any)=>t>=s.start&&t<s.end));const spoken=audioTiming.flatMap(q=>q.captions).find(c=>seconds>=c.start&&seconds<=c.end)?.text||'';
 return <div style={{position:'absolute',inset:0,pointerEvents:'none',fontFamily:'Jakarta',color:ink}}>
  {scenes.map((s:any)=>{const opacity=smooth((t-s.start+.3)/.7)*(1-smooth((t-s.end+.5)/.7));if(opacity===0)return null;return <div key={s.start} style={{position:'absolute',top:46,left:78,opacity,transform:`translateY(${12*(1-opacity)}px)`}}><div style={{fontSize:48,fontWeight:750,lineHeight:1.15,textShadow:'0 1px 3px #fff5df55'}}>{s.title}</div><div style={{width:88,height:5,background:'#edbd49',marginTop:14}}/></div>})}
  <Img src={staticFile('logo.png')} style={{position:'absolute',top:30,right:94,width:75,height:75,objectFit:'contain'}}/>
  <div style={{position:'absolute',top:111,right:70,fontSize:20,fontWeight:750}}>CPNS Journey</div>
  {spoken&&<div data-caption style={{position:'absolute',bottom:74,left:'50%',transform:'translateX(-50%)',maxWidth:1540,width:'max-content',padding:'16px 30px',borderRadius:18,background:'rgba(255,248,233,.96)',boxShadow:'0 3px 18px #30291c18',fontSize:32,fontWeight:650,lineHeight:1.4,textAlign:'center'}}>{spoken}</div>}
  {idx===6&&<div style={{position:'absolute',bottom:184,right:83,fontSize:21,fontWeight:650,background:'#fff4df',borderRadius:20,padding:'8px 19px'}}>Contoh latihan</div>}
  {t>116&&<div style={{position:'absolute',bottom:35,width:'100%',textAlign:'center',fontSize:18,fontWeight:600}}>Aplikasi independen • Bukan produk resmi BKN/Kemenkeu</div>}
  <div style={{position:'absolute',height:3,left:78,right:78,bottom:23,background:'#25465d20'}}><div style={{height:3,width:`${100*seconds/DURATION}%`,background:'#e5b742'}}/></div>
 </div>;
};
