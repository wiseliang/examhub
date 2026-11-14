export function chinaDay(now=new Date()){return new Intl.DateTimeFormat('sv-SE',{timeZone:'Asia/Shanghai'}).format(now);}
export function validateGoal(input, today=chinaDay()) {
 const goal={};for(const [key,max] of [['exam',120],['region',80],['level',160],['preferences',600]]){if(typeof input?.[key]!=='string'||input[key].length>max)throw Error('备考目标字段无效。');goal[key]=input[key].trim();}
 if(!goal.exam)throw Error('请填写考试名称。');
 const date=input.targetDate;if(typeof date!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(date)||!Number.isFinite(Date.parse(date))||new Date(date).toISOString().slice(0,10)!==date)throw Error('请选择有效的复习截止日期。');
 const days=(Date.parse(date)-Date.parse(today))/86400000;if(days<1||days>730)throw Error('截止日期须在未来 1 至 730 天内。');
 if(!Number.isInteger(input.minutes)||input.minutes<15||input.minutes>480)throw Error('每天可用时间须为 15 至 480 分钟。');
 const studyDays=input.studyDays??[1,2,3,4,5,6,7];
 if(!Array.isArray(studyDays)||!studyDays.length||studyDays.length>7||studyDays.some(d=>!Number.isInteger(d)||d<1||d>7))throw Error('每周至少选择一个有效学习日。');
 const selected=[...new Set(studyDays)].sort();
 if(!Array.from({length:days},(_,d)=>new Date(Date.parse(today)+d*86400000).getUTCDay()||7).some(d=>selected.includes(d)))throw Error('截止日前没有选定的学习日，请调整日期或学习日。');
 return {...goal,targetDate:date,minutes:input.minutes,studyDays:selected};
}
export function plan(goal,research,today=chinaDay()) {
 const calendarDays=Math.round((Date.parse(goal.targetDate)-Date.parse(today))/86400000),tasks=[];
 const dates=Array.from({length:calendarDays},(_,d)=>new Date(Date.parse(today)+d*86400000)).filter(date=>(goal.studyDays??[1,2,3,4,5,6,7]).includes(date.getUTCDay()||7));
 const days=dates.length;
 const subjects=research.subjects;
 for(let d=0;d<days;d++){
  const date=dates[d].toISOString().slice(0,10);
  const subject=subjects[d%subjects.length];
  const phase=d<Math.floor(days*.55)?'理解基础':d<Math.floor(days*.85)?'专项练习':'模拟与错题复盘';
  const review=Math.max(5,Math.floor(goal.minutes*.25));
  tasks.push({id:`${date}-study`,date,subject:subject.name,title:`${phase}：${subject.focus}`,minutes:goal.minutes-review,done:false});
  tasks.push({id:`${date}-review`,date,subject:subject.name,title:'回忆昨日重点，整理错题与未掌握内容',minutes:review,done:false});
 }
 return {startDate:today,targetDate:goal.targetDate,totalMinutes:days*goal.minutes,days,tasks,notice:'这是按个人截止日与每日时间生成的建议，不代表已确认考试日期；题量按实际做题速度调整。'};
}
