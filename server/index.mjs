import http from 'node:http';
import {createHash, randomUUID, timingSafeEqual} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {research} from './research.mjs';
import {validateGoal, plan} from './planner.mjs';
export function createService({tokens,run=research,now=()=>Date.now()}={}){
 if(!Array.isArray(tokens)||!tokens.length||tokens.some(t=>typeof t!=='string'||t.length<32))throw Error('请配置至少 32 位的个人访问码；不能把 Codex 密钥作为访问码。');
 const digest=s=>createHash('sha256').update(s).digest();const owners=tokens.map(digest);const jobs=new Map(),limits=new Map();let busy=false;
 const send=(res,status,data)=>{res.writeHead(status,{'content-type':'application/json; charset=utf-8','cache-control':'no-store','x-content-type-options':'nosniff'});res.end(JSON.stringify(data));};
 const server=http.createServer(async(req,res)=>{
  try {
   const token=req.headers.authorization?.replace(/^Bearer /,'')??'';const hash=digest(token);const owner=owners.findIndex(x=>timingSafeEqual(x,hash));
   if(owner<0)return send(res,401,{error:'访问码无效，请重新连接备考服务。'});
   if(req.method==='GET'&&req.url==='/v1/health')return send(res,200,{service:'examhub-assistant',version:1});
   for(const [id,j] of jobs)if(now()-j.createdAt>3600000&&!['running'].includes(j.status))jobs.delete(id);
   const match=/^\/v1\/research\/([a-f0-9-]+)$/.exec(req.url??'');
   if(match){const job=jobs.get(match[1]);if(!job||job.owner!==owner)return send(res,404,{error:'研究任务不存在或已过期。'});
    if(req.method==='DELETE'){if(job.status==='running'){job.controller.abort();job.status='cancelled';job.message='已停止研究';}return send(res,200,{status:job.status});}
    if(req.method==='GET'){const {controller,owner:_,...visible}=job;return send(res,200,visible);}
   }
   if(req.method!=='POST'||req.url!=='/v1/research')return send(res,404,{error:'接口不存在。'});
   if(!req.headers['content-type']?.startsWith('application/json'))return send(res,415,{error:'仅接受 JSON。'});
   let data='',bytes=0;for await(const chunk of req){bytes+=chunk.length;if(bytes>8192){send(res,413,{error:'输入内容过长。'});req.destroy();return;}data+=chunk;}
   let goal;try{goal=validateGoal(JSON.parse(data));}catch(e){return send(res,400,{error:e instanceof SyntaxError?'目标格式无效。':e.message});}
   if(busy)return send(res,429,{error:'备考服务正在研究其他目标，请稍后重试。'});
   const recent=(limits.get(owner)??[]).filter(t=>now()-t<3600000);if(recent.length>=6)return send(res,429,{error:'每小时最多研究 6 次，请先查看已有结果。'});
   recent.push(now());limits.set(owner,recent);busy=true;
   const id=randomUUID(),controller=new AbortController();const job={id,owner,goal,createdAt:now(),status:'running',message:'正在检索主办方、大纲和合适题库',controller};jobs.set(id,job);send(res,202,{id,status:job.status});
   Promise.resolve().then(()=>run(goal,{signal:controller.signal,onProgress:message=>{job.message=message;}})).then(result=>{if(job.status!=='running')return;job.result={...result,plan:plan(goal,result)};job.status='completed';job.message='研究完成，请核对来源并开始复习';}).catch(()=>{if(job.status==='running'){job.status='failed';job.message='联网研究失败或超时。请检查服务端 Codex 登录与搜索权限后重试。';}}).finally(()=>{busy=false;});
  }catch{if(!res.headersSent)send(res,500,{error:'服务暂时不可用，请稍后重试。'});else res.end();}
 });
 server.requestTimeout=15000;server.headersTimeout=10000;
 server.on('close',()=>{for(const j of jobs.values())j.controller.abort();});return server;
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 const tokens=JSON.parse(process.env.EXAMHUB_ACCESS_TOKENS??'[]');const server=createService({tokens});
 server.listen(Number(process.env.PORT??8788),process.env.HOST??'127.0.0.1',()=>console.log('考试通备考服务已启动（默认仅本机访问）'));
 for(const event of ['SIGTERM','SIGINT'])process.once(event,()=>{server.closeAllConnections();server.close();});
}
