import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,writeFile,rm,chmod} from 'node:fs/promises';
import path from 'node:path';
import {tmpdir} from 'node:os';
import {research} from '../research.mjs';
const result={summary:'固定测试结果',subjects:[{name:'基础',focus:'重点'}],sources:[],banks:[],uncertainties:[]};
async function executable(t,body){const dir=await mkdtemp(path.join(tmpdir(),'examhub-provider-test-'));t.after(()=>rm(dir,{recursive:true,force:true}));const bin=path.join(dir,'fixture.mjs');await writeFile(bin,'#!/usr/bin/env node\n'+body);await chmod(bin,0o700);return bin;}
test('消费 CLI 搜索事件和结构化消息，而不是把固定文本冒充联网',async(t)=>{const bin=await executable(t,`process.stdin.resume();process.stdin.on('end',()=>{console.log(JSON.stringify({type:'item.completed',item:{type:'web_search'}}));console.log(JSON.stringify({type:'item.completed',item:{type:'agent_message',text:${JSON.stringify(JSON.stringify(result))}}}));});`);const value=await research({}, {bin});assert.equal(value.searches,1);assert.equal(value.summary,result.summary);});
test('没有真实工具完成事件时拒绝结果',async(t)=>{const bin=await executable(t,`console.log(JSON.stringify({type:'item.completed',item:{type:'agent_message',text:${JSON.stringify(JSON.stringify(result))}}}));`);await assert.rejects(research({}, {bin}),/未执行联网检索/);});
test('超时实际终止子进程，不会无限占用单并发服务',async(t)=>{const bin=await executable(t,'setInterval(()=>{},1000);');await assert.rejects(research({}, {bin,timeout:100}),/联网研究未完成/);});
