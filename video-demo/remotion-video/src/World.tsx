import React,{useLayoutEffect,useMemo}from'react';
import {useThree}from'@react-three/fiber';
import {useCurrentFrame,useVideoConfig}from'remotion';
import {cameraAt}from'./camera';
import {createWorld}from'./engine/world';
import {baseTime}from'./timeline';
export const World:React.FC<{images:Record<string,HTMLImageElement>}>=({images})=>{
 const frame=useCurrentFrame(),{fps}=useVideoConfig(),{camera}=useThree();
 const world=useMemo(()=>createWorld(images),[images]);
 useLayoutEffect(()=>{const t=baseTime(frame/fps),c=cameraAt(t);world.seek(t);camera.position.set(...c.position as [number,number,number]);camera.lookAt(...c.target as [number,number,number]);(camera as any).fov=c.fov;(camera as any).updateProjectionMatrix();world.scene.updateMatrixWorld(true);},[frame,fps,camera,world]);
 return <primitive object={world.scene}/>;
};
