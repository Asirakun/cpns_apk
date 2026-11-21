import fs from 'node:fs';
import {openBrowser} from '@remotion/renderer';

export async function openVerifiedGpuBrowser() {
  const chromiumOptions = {gl: 'angle', flags: {
    'use-angle': 'd3d11', force_high_performance_gpu: true,
    'enable-gpu-rasterization': true, 'disable-gpu-rasterization': false,
    'enable-zero-copy': true,
  }};
  const browser = await openBrowser('chrome', {chromiumOptions, logLevel: 'error'});
  try {
    const page = await browser.newPage({context: null, logLevel: 'error', indent: false,
      pageIndex: 0, onBrowserLog: null, onLog: () => {}});
    const webgl = await page.evaluate(() => {
      const gl = document.createElement('canvas').getContext('webgl2');
      if (!gl) return {error: 'WebGL2 unavailable'};
      const debug = gl.getExtension('WEBGL_debug_renderer_info');
      return {renderer: gl.getParameter(debug.UNMASKED_RENDERER_WEBGL), vendor: gl.getParameter(debug.UNMASKED_VENDOR_WEBGL)};
    });
    const info = (await browser.connection.send('SystemInfo.getInfo')).value;
    const report = {checkedAt: new Date().toISOString(), webgl, devices: info.gpu.devices,
      featureStatus: info.gpu.featureStatus, auxAttributes: info.gpu.auxAttributes, chromiumOptions};
    fs.mkdirSync('out/hd', {recursive:true});
    fs.writeFileSync('out/hd/gpu.json', JSON.stringify(report,null,2)+'\n');
    if (!/NVIDIA.*RTX 3050/i.test(webgl.renderer || '')) throw new Error('Renderer is not the requested RTX 3050: '+JSON.stringify(webgl));
    console.log(JSON.stringify({renderer: webgl.renderer, featureStatus: report.featureStatus},null,2));
    await page.close();
    return {browser, report};
  } catch (error) { await browser.close({silent:true}); throw error; }
}
if (process.argv.includes('--probe')) {
  const {browser} = await openVerifiedGpuBrowser();
  await browser.close({silent:true});
}
