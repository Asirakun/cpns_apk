import React from 'react';
import {AbsoluteFill, Composition, Img, interpolate, registerRoot, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {DebugCtx, McBox} from './debug';

type Props = {mcDebug?: boolean};
const Mark: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const reveal = spring({frame, fps, config: {damping: 20, stiffness: 90, mass: .9}});
  return <AbsoluteFill style={{background:'transparent'}}>
    <Img src={staticFile('intro-logo.png')} style={{position:'absolute',left:'6%',top:'6%',width:'88%',height:'88%',objectFit:'contain',
      opacity:reveal, transform:`translateY(${(1-reveal)*65}px) rotate(${(1-reveal)*-8}deg) scale(${.8+.2*reveal})`,
      filter:'drop-shadow(0 12px 12px #03162955)'}}/>
  </AbsoluteFill>;
};

// Preview uses the same plain navy, subtle dots/arcs and native text layout as
// Flutter. The APK receives ONLY the transparent mark: no baked background or text.
const Backdrop: React.FC = () => <svg width="1440" height="3200" viewBox="0 0 360 800" style={{position:'absolute',inset:0}} aria-hidden>
  {Array.from({length:28},(_,row)=>Array.from({length:13},(_,col)=>{
    const y=9+row*29,x=9+col*29+Math.sin(y*.13)*4;
    return <circle key={`${row}-${col}`} cx={x} cy={y} r={.7} fill="#B9D9F0" opacity={.045}/>;
  }))}
  {[0,1,2,3].map(i=><circle key={i} cx={378} cy={424} r={105+i*15} fill="none" stroke="#B9D9F0" strokeWidth={1} opacity={.035}/>)}
</svg>;
const Intro:React.FC<Props>=({mcDebug=false})=>{
  const frame=useCurrentFrame();
  const title=interpolate(frame,[21,33],[0,1],{extrapolateLeft:'clamp',extrapolateRight:'clamp'});
  const subtitle=interpolate(frame,[29,40],[0,1],{extrapolateLeft:'clamp',extrapolateRight:'clamp'});
  return <DebugCtx.Provider value={mcDebug}><AbsoluteFill style={{background:'#08223B',fontFamily:'PlusJakarta',color:'#FFF1D9',alignItems:'center',justifyContent:'center'}}>
    <style>{`@font-face{font-family:PlusJakarta;src:url('${staticFile('PlusJakartaSans.ttf')}')}*{box-sizing:border-box}`}</style>
    <Backdrop/>
    <div style={{position:'relative',display:'flex',flexDirection:'column',alignItems:'center'}}>
      <McBox kind="block" style={{position:'relative',width:1036.8,height:1036.8}}><Mark/></McBox>
      <McBox kind="text" style={{width:1320,height:140.4,marginTop:48,opacity:title,transform:`translateY(${(1-title)*16}px)`}}>
        <div style={{fontSize:108,fontWeight:800,textAlign:'center',letterSpacing:-2,lineHeight:'140.4px'}}>CPNS Journey</div>
      </McBox>
      <McBox kind="text" style={{width:1320,height:81,marginTop:24,opacity:subtitle}}>
        <div style={{fontSize:54,color:'#B1C3D8',textAlign:'center',lineHeight:'81px'}}>Persiapan yang terarah</div>
      </McBox>
      <div style={{height:8,width:168,borderRadius:4,background:'#EAC16C',marginTop:48,opacity:subtitle}}/>
    </div>
  </AbsoluteFill></DebugCtx.Provider>;
};
const Root:React.FC=()=><>
  <Composition id="Intro" component={Intro} width={1440} height={3200} fps={30} durationInFrames={96} defaultProps={{mcDebug:false}}/>
  <Composition id="IntroMark" component={Mark} width={1080} height={1080} fps={30} durationInFrames={96}/>
</>;
registerRoot(Root);
