-- ============================================================
-- 京淼面诊平台 · 数据库初始化脚本
-- 用法：复制全部内容 → Supabase 后台 → SQL Editor → New query
--      → 粘贴 → 点 "Run" → 看到 "Success" 即可（只需跑一次）
-- ============================================================

-- 1) 门店 / 租户表
create table if not exists public.tenants (
  id            uuid primary key default gen_random_uuid(),
  slug          text unique not null,
  brand_name    text not null,
  primary_color text default '#C0392B',
  logo_url      text,
  owner_email   text,
  active        boolean default true,
  created_at    timestamptz default now()
);

-- 2) 门店账号表（关联 Supabase Auth 用户）
create table if not exists public.store_users (
  id         uuid primary key references auth.users(id) on delete cascade,
  tenant_id  uuid references public.tenants(id) on delete cascade,
  email      text,
  role       text default 'staff',   -- staff = 门店 ; platform = 平台管理员
  created_at timestamptz default now()
);

-- 3) 顾客填写记录表
create table if not exists public.submissions (
  id            uuid primary key default gen_random_uuid(),
  tenant_id     uuid references public.tenants(id) on delete cascade,
  customer_name text,
  data          jsonb not null default '{}'::jsonb,
  created_at    timestamptz default now()
);

-- 索引
create index if not exists idx_submissions_tenant on public.submissions(tenant_id);
create index if not exists idx_store_users_tenant on public.store_users(tenant_id);

-- 4) 开启行级安全（RLS）—— 数据隔离的核心
alter table public.tenants      enable row level security;
alter table public.store_users  enable row level security;
alter table public.submissions  enable row level security;

-- 4.1) 判断当前登录用户是否为平台管理员（SECURITY DEFINER 绕过 RLS，避免策略递归）
create or replace function public.is_platform() returns boolean
language sql security definer set search_path = public as $$
  select exists (
    select 1 from public.store_users su where su.id = auth.uid() and su.role = 'platform'
  );
$$;
revoke all on function public.is_platform() from public;
grant execute on function public.is_platform() to authenticated, anon;

-- 4.2) 给角色授权（RLS 策略之外必须显式 GRANT，否则插入/读取会被拒）
grant usage on schema public to anon, authenticated;
grant select                                  on public.tenants      to anon, authenticated;
grant select, insert, update, delete          on public.submissions  to authenticated;
grant select, insert, update, delete          on public.store_users  to authenticated;
grant select, insert                          on public.submissions  to anon;   -- 顾客匿名仅能提交，不能读/改/删（读被 RLS 策略拦截）

-- 5) 存储桶：门店 logo（公开读）
insert into storage.buckets (id, name, public)
values ('logos','logos', true)
on conflict (id) do nothing;

-- 开放 logos 桶的公开读权限
drop policy if exists "logos_public_read" on storage.objects;
create policy "logos_public_read" on storage.objects
  for select using ( bucket_id = 'logos' );

-- ============================================================
-- 6) RLS 策略
-- ============================================================

-- tenants：品牌信息任何人可读（供填写页按 slug 加载）
drop policy if exists "tenants_public_read" on public.tenants;
create policy "tenants_public_read" on public.tenants
  for select using (true);

-- 门店可更新自己的品牌信息（店名/主题色/logo）
drop policy if exists "tenants_store_update" on public.tenants;
create policy "tenants_store_update" on public.tenants
  for update using (
    exists (select 1 from public.store_users su where su.id = auth.uid() and su.tenant_id = tenants.id)
  );

-- store_users：用户只能看自己的行
drop policy if exists "store_users_self" on public.store_users;
create policy "store_users_self" on public.store_users
  for select using (auth.uid() = id);

-- submissions：顾客（匿名）可提交到有效门店；门店只能看/删自己的数据
drop policy if exists "submissions_anon_insert" on public.submissions;
create policy "submissions_anon_insert" on public.submissions
  for insert to anon with check (tenant_id is not null);

drop policy if exists "submissions_store_read" on public.submissions;
create policy "submissions_store_read" on public.submissions
  for select using (
    tenant_id = (select tenant_id from public.store_users su where su.id = auth.uid())
  );

drop policy if exists "submissions_store_write" on public.submissions;
create policy "submissions_store_write" on public.submissions
  for update using (
    tenant_id = (select tenant_id from public.store_users su where su.id = auth.uid())
  );

drop policy if exists "submissions_store_del" on public.submissions;
create policy "submissions_store_del" on public.submissions
  for delete using (
    tenant_id = (select tenant_id from public.store_users su where su.id = auth.uid())
  );

-- 平台管理员（role='platform'）可看/改/删所有数据
drop policy if exists "platform_all_tenants" on public.tenants;
create policy "platform_all_tenants" on public.tenants
  for all using ( public.is_platform() );

drop policy if exists "platform_all_store_users" on public.store_users;
create policy "platform_all_store_users" on public.store_users
  for all using ( public.is_platform() );

drop policy if exists "platform_all_submissions" on public.submissions;
create policy "platform_all_submissions" on public.submissions
  for all using ( public.is_platform() );

-- ============================================================
-- 7) 新建门店的安全函数（平台管理员在后台调用，自动建账号+建门店）
-- ============================================================
create or replace function public.create_store(
  p_slug text,
  p_brand_name text,
  p_email text,
  p_password text,
  p_color text default '#C0392B',
  p_logo_url text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_tenant uuid;
  new_user   uuid;
  caller     uuid := nullif(current_setting('request.jwt.claims', true)::json->>'sub','');
begin
  -- 仅平台管理员可调用
  if not exists (select 1 from public.store_users su where su.id = caller and su.role='platform') then
    raise exception '无权限：仅平台管理员可新建门店';
  end if;

  -- 创建 / 更新门店
  insert into public.tenants (slug, brand_name, primary_color, logo_url, owner_email)
  values (p_slug, p_brand_name, p_color, p_logo_url, p_email)
  on conflict (slug) do update set
    brand_name   = p_brand_name,
    primary_color= p_color,
    logo_url     = coalesce(p_logo_url, tenants.logo_url),
    owner_email  = p_email
  returning id into new_tenant;

  -- 创建认证账号（若不存在）
  -- 注意：新版 Supabase auth.users 的 email 无唯一约束，改用先查后插
  select id into new_user from auth.users where email = p_email;
  if new_user is null then
    insert into auth.users (
      id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at, instance_id
    ) values (
      gen_random_uuid(), 'authenticated','authenticated', p_email,
      crypt(p_password, gen_salt('bf')), now(), now(), now(),
      '00000000-0000-0000-0000-000000000000'
    )
    returning id into new_user;
  end if;

  -- 关联账号到门店
  insert into public.store_users (id, tenant_id, email, role)
  values (new_user, new_tenant, p_email, 'staff')
  on conflict (id) do nothing;

  return new_tenant;
end;
$$;

revoke all on function public.create_store(text,text,text,text,text,text) from public;
grant  execute on function public.create_store(text,text,text,text,text,text) to authenticated;

-- ============================================================
-- 8) 预置数据：平台管理员 + 示例门店（可直接测试）
-- ============================================================
do $$
declare
  pid uuid;
  did uuid;
  su  uuid;
begin
  -- 平台管理员（你自己的账号）
  select id into pid from auth.users where email = '910747517@qq.com';
  if pid is null then
    insert into auth.users (
      id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at, instance_id
    ) values (
      gen_random_uuid(), 'authenticated','authenticated', '910747517@qq.com',
      crypt('Jingmiao@2026', gen_salt('bf')), now(), now(), now(),
      '00000000-0000-0000-0000-000000000000'
    )
    returning id into pid;
  end if;

  -- 示例门店租户
  insert into public.tenants (slug, brand_name, primary_color, owner_email)
  values ('demo', '示例门店 Demo', '#C0392B', '910747517@qq.com')
  on conflict (slug) do nothing
  returning id into did;

  -- 平台管理员角色关联（tenant_id 为空表示平台）
  insert into public.store_users (id, tenant_id, email, role)
  values (pid, null, '910747517@qq.com', 'platform')
  on conflict (id) do nothing;

  -- 示例门店账号
  select id into su from auth.users where email = 'demo@store.com';
  if su is null then
    insert into auth.users (
      id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at, instance_id
    ) values (
      gen_random_uuid(), 'authenticated','authenticated', 'demo@store.com',
      crypt('demo1234', gen_salt('bf')), now(), now(), now(),
      '00000000-0000-0000-0000-000000000000'
    )
    returning id into su;
  end if;
  insert into public.store_users (id, tenant_id, email, role)
  values (su, did, 'demo@store.com', 'staff')
  on conflict (id) do nothing;
end $$;

-- 完成提示
select '初始化完成：平台管理员 910747517@qq.com / Jingmiao@2026 ；示例门店 demo@store.com / demo1234' as result;
