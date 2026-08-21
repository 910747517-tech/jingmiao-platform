-- 京淼面诊系统 · 单门店云端初始化
-- 在 Supabase SQL Editor 中整段执行一次。

create extension if not exists pgcrypto;

create table if not exists public.tenants (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  brand_name text not null,
  primary_color text default '#9D4D3F',
  logo_url text,
  owner_email text not null,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.store_users (
  id uuid primary key references auth.users(id) on delete cascade,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  email text,
  role text default 'staff',
  created_at timestamptz default now()
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  customer_name text,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz default now()
);

create index if not exists idx_submissions_tenant_created
  on public.submissions(tenant_id, created_at desc);
create index if not exists idx_store_users_tenant on public.store_users(tenant_id);

alter table public.tenants enable row level security;
alter table public.store_users enable row level security;
alter table public.submissions enable row level security;

grant usage on schema public to anon, authenticated;
revoke all on public.tenants, public.store_users, public.submissions from anon, authenticated;
grant select(id,slug,brand_name,primary_color,logo_url,active) on public.tenants to anon;
grant select, update on public.tenants to authenticated;
grant select on public.store_users to authenticated;
grant select, delete on public.submissions to authenticated;

drop policy if exists tenants_public_read on public.tenants;
create policy tenants_public_read on public.tenants for select using (active = true);

drop policy if exists tenants_staff_update on public.tenants;
create policy tenants_staff_update on public.tenants for update to authenticated using (
  exists(select 1 from public.store_users su where su.id = auth.uid() and su.tenant_id = tenants.id)
);

drop policy if exists store_users_self on public.store_users;
create policy store_users_self on public.store_users for select to authenticated using (id = auth.uid());

drop policy if exists submissions_staff_read on public.submissions;
create policy submissions_staff_read on public.submissions for select to authenticated using (
  exists(select 1 from public.store_users su where su.id = auth.uid() and su.tenant_id = submissions.tenant_id)
);

drop policy if exists submissions_staff_delete on public.submissions;
create policy submissions_staff_delete on public.submissions for delete to authenticated using (
  exists(select 1 from public.store_users su where su.id = auth.uid() and su.tenant_id = submissions.tenant_id)
);

create or replace function public.submit_form(p_data jsonb) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_tenant uuid; v_id uuid;
begin
  v_tenant := (p_data->>'tenant_id')::uuid;
  if not exists(select 1 from public.tenants where id=v_tenant and active=true) then
    raise exception '无效的门店';
  end if;
  insert into public.submissions(tenant_id,customer_name,data)
  values(v_tenant,p_data->>'customer_name',p_data-array['tenant_id','customer_name']::text[])
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.submit_form(jsonb) from public;
grant execute on function public.submit_form(jsonb) to anon, authenticated;

-- 登录后仅允许门店登记邮箱认领门店账号，不在代码中保存任何密码。
create or replace function public.claim_store() returns uuid
language plpgsql security definer set search_path = public as $$
declare v_email text; v_tenant uuid;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if v_email = '' then raise exception '请先登录'; end if;
  select id into v_tenant from public.tenants
    where lower(owner_email)=v_email and active=true limit 1;
  if v_tenant is null then raise exception '该邮箱未登记为门店账号'; end if;
  insert into public.store_users(id,tenant_id,email,role)
  values(auth.uid(),v_tenant,v_email,'staff')
  on conflict(id) do update set tenant_id=excluded.tenant_id,email=excluded.email;
  return v_tenant;
end;
$$;
revoke all on function public.claim_store() from public;
grant execute on function public.claim_store() to authenticated;

insert into public.tenants(slug,brand_name,primary_color,owner_email)
values('jingmiao','京淼','#9D4D3F','910747517@qq.com')
on conflict(slug) do update set
  brand_name=excluded.brand_name,
  primary_color=excluded.primary_color,
  owner_email=excluded.owner_email,
  active=true;

insert into storage.buckets(id,name,public)
values('logos','logos',true) on conflict(id) do nothing;
drop policy if exists logos_public_read on storage.objects;
create policy logos_public_read on storage.objects for select using(bucket_id='logos');
drop policy if exists logos_staff_upload on storage.objects;
create policy logos_staff_upload on storage.objects for insert to authenticated
  with check(bucket_id='logos' and exists(select 1 from public.store_users where id=auth.uid()));

select '京淼云端数据库初始化完成' as result;
