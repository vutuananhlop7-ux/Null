/* Nova gate — do Nova Admin tạo. Không chỉnh sửa. */
(function(PUB){
  'use strict';
  if(!PUB)return;
  const LK='nova-lic-v1',UK='nova-use-v1',T0=Date.now();
  const dec=s=>{s=s.replace(/-/g,'+').replace(/_/g,'/');while(s.length%4)s+='=';const b=atob(s),a=new Uint8Array(b.length);for(let i=0;i<b.length;i++)a[i]=b.charCodeAt(i);return a};
  const ld=k=>{try{return JSON.parse(localStorage.getItem(k)||'null')}catch(_){return null}};
  const sv=(k,v)=>{try{localStorage.setItem(k,JSON.stringify(v))}catch(_){}};
  const day=()=>{const d=new Date();return d.getFullYear()+'-'+(d.getMonth()+1)+'-'+d.getDate()};
  let keyP=null;
  const pub=()=>keyP||(keyP=crypto.subtle.importKey('jwk',PUB,{name:'ECDSA',namedCurve:'P-256'},false,['verify']));
  async function verify(tok){
    const p=String(tok||'').trim().split('.');if(p.length!==2)return null;
    try{
      const ok=await crypto.subtle.verify({name:'ECDSA',hash:'SHA-256'},await pub(),dec(p[1]),dec(p[0]));
      if(!ok)return null;return JSON.parse(new TextDecoder().decode(dec(p[0])));
    }catch(_){return null}
  }
  let lic=null,usage=ld(UK)||{day:day(),sec:0,seen:0},locked=true,reason='',busy=true,badge=null,ov=null;
  const fmt=ms=>{const m=Math.max(0,Math.floor(ms/60000)),d=Math.floor(m/1440),h=Math.floor(m%1440/60),n=m%60;return d?d+' ngày '+h+' giờ':h?h+' giờ '+n+' phút':n+' phút'};
  const expOf=()=>lic.p.exp?lic.p.exp:lic.act+lic.p.dur;
  function evalState(){
    if(!lic){locked=true;return}
    const now=Date.now();
    if(usage.seen&&now<usage.seen-5*60000){locked=true;reason='Đồng hồ máy bị chỉnh lùi. Hãy chỉnh lại giờ đúng rồi tải lại trang.';return}
    if(now>=expOf()){locked=true;reason='Tài khoản đã hết hạn. Hãy xin mã mới từ người quản lý.';return}
    if(usage.day!==day()){usage={day:day(),sec:0,seen:now}}
    if(lic.p.daily>0&&usage.sec>=lic.p.daily*60){locked=true;reason='Đã dùng hết '+lic.p.daily+' phút của hôm nay. Quay lại vào ngày mai.';return}
    locked=false;reason='';
  }
  function ui(){
    if(!document.body)return;
    if(!ov||!ov.isConnected){
      ov=document.createElement('div');ov.id='novaGate';
      ov.style.cssText='position:fixed;inset:0;z-index:2147483000;background:rgba(5,4,15,.97);color:#EAF0FF;display:none;align-items:center;justify-content:center;font:14px/1.5 "Segoe UI",system-ui,sans-serif;padding:16px';
      ov.innerHTML='<div style="max-width:420px;width:100%;background:#0d0a2b;border:1px solid #26F0FF;border-radius:16px;padding:20px;box-shadow:0 0 40px rgba(38,240,255,.25)"><div style="font-weight:800;font-size:20px;background:linear-gradient(90deg,#26F0FF,#FF3DA5);-webkit-background-clip:text;background-clip:text;color:transparent">NOVA SLIDES</div><div id="ngMsg" style="margin:10px 0;color:#9BA1D4"></div><textarea id="ngKey" rows="4" placeholder="Dán mã kích hoạt vào đây" style="width:100%;background:#05040F;color:#EAF0FF;border:1px solid #3a3470;border-radius:8px;padding:8px;font:12px monospace"></textarea><div id="ngErr" style="color:#FF6B7A;min-height:20px;margin:6px 0"></div><button id="ngGo" style="width:100%;padding:10px;border:0;border-radius:10px;font-weight:700;background:linear-gradient(90deg,#26F0FF,#8A5BFF);color:#05040F;cursor:pointer">Kích hoạt</button></div>';
      document.body.appendChild(ov);
      ov.querySelector('#ngGo').onclick=async()=>{
        const e=ov.querySelector('#ngErr');e.textContent='';
        const t=ov.querySelector('#ngKey').value.trim(),p=await verify(t);
        if(!p){e.textContent='Mã không hợp lệ.';return}
        const same=lic&&lic.p.id===p.id;
        const act=same?lic.act:Date.now();
        const L={tok:t,act,p};
        if((L.p.exp||act+L.p.dur)<=Date.now()){e.textContent='Mã này đã hết hạn.';return}
        lic=L;sv(LK,{tok:t,act});if(!same)usage={day:day(),sec:0,seen:Date.now()};sv(UK,usage);evalState();ui();
      };
      ov.addEventListener('keydown',e=>e.stopPropagation(),true);
    }
    if(!badge||!badge.isConnected){
      badge=document.createElement('div');
      badge.style.cssText='position:fixed;left:8px;bottom:8px;z-index:2147482999;background:rgba(13,10,43,.85);color:#9BA1D4;border:1px solid rgba(120,110,255,.4);border-radius:10px;padding:2px 9px;font:11px "Segoe UI",sans-serif;pointer-events:none';
      document.body.appendChild(badge);
    }
    ov.style.display=locked?'flex':'none';
    if(locked){ov.querySelector('#ngMsg').textContent=reason||(busy?'Đang kiểm tra…':'Nhập mã kích hoạt để sử dụng.')}
    if(lic&&!locked){
      const left=expOf()-Date.now();let t='Còn '+fmt(left);
      if(lic.p.daily>0)t+=' · hôm nay còn '+Math.max(0,Math.ceil(lic.p.daily-usage.sec/60))+' phút';
      badge.textContent=lic.p.name+' · '+t;badge.style.display='block';
    }else badge.style.display='none';
  }
  async function boot(){
    const s=ld(LK);
    if(s){const p=await verify(s.tok);if(p)lic={tok:s.tok,act:s.act||Date.now(),p}}
    busy=false;evalState();ui();
    setInterval(()=>{
      if(lic&&!locked&&!document.hidden){if(usage.day!==day())usage={day:day(),sec:0,seen:0};usage.sec++}
      if(!lic||!locked)usage.seen=Math.max(usage.seen||0,Date.now());
      evalState();ui();
      if(usage.sec%5===0)sv(UK,usage);
      if(locked&&typeof presClose==='function'&&typeof P!=='undefined'&&P&&P.on){try{presClose()}catch(_){}}
    },1000);
    addEventListener('keydown',e=>{if(locked&&!(e.target&&e.target.closest&&e.target.closest('#novaGate'))){e.stopImmediatePropagation();e.preventDefault()}},true);
    document.addEventListener('visibilitychange',()=>sv(UK,usage));
    addEventListener('beforeunload',()=>sv(UK,usage));
  }
  const start=()=>{ui();boot()};
  if(document.body)start();else document.addEventListener('DOMContentLoaded',start);
})({"crv":"P-256","ext":true,"key_ops":["verify"],"kty":"EC","x":"F1qgonP8FgQiMjXpE-5MobRTcSdEtJSJeHgTtUHQVP0","y":"Dmn4QCSjB7rQFD2RLEW0cjEpmliqtCFB_O3KTfo88co"});
