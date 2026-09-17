const { chromium } = require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:900},deviceScaleFactor:1});
 const errors=[]; page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});page.on('pageerror',e=>errors.push(String(e)));
 await page.goto('http://127.0.0.1:8086',{waitUntil:'networkidle'});
 await page.screenshot({path:'artifacts/pixellab-world1-map/app-installed.png',fullPage:true});
 const imgs=await page.locator('img').evaluateAll(xs=>xs.filter(x=>x.src.includes('map-w1')||x.src.includes('building-')||x.src.includes('world1')).map(x=>({src:x.src.split('/').pop(),nw:x.naturalWidth,nh:x.naturalHeight,rect:x.getBoundingClientRect().toJSON()})));
 console.log(JSON.stringify({errors,images:imgs},null,2)); await browser.close();
})();
