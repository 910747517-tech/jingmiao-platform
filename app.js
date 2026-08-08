// 京淼面诊平台 · 共享 Supabase 客户端
// 注意：这里只放 anon（publishable）key，绝不放 service_role key
const SUPABASE_URL = 'https://tdpfhzevydqojxlllefx.supabase.co';
const SUPABASE_ANON = 'sb_publishable_eNxxyBBCWtzUmMGKeBdT3A_lYQ9IA8D';

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON);

// 通用提示
function toast(msg){
  let t=document.getElementById('toast');
  if(!t){ t=document.createElement('div'); t.id='toast'; t.className='toast'; document.body.appendChild(t); }
  t.textContent=msg; t.classList.add('show'); setTimeout(()=>t.classList.remove('show'),2600);
}

// 注销
async function logout(){ await sb.auth.signOut(); location.href='login.html'; }
