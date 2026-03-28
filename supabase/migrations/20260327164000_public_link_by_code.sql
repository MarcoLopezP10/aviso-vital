create table if not exists public.vinculaciones (
  id uuid primary key default gen_random_uuid(),
  id_administrador uuid not null references public.usuarios (id) on delete cascade,
  codigo_vinculacion text not null,
  dispositivo_id text not null,
  nombre_usuario_mayor text,
  activa boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists vinculaciones_admin_idx
on public.vinculaciones (id_administrador);

create unique index if not exists vinculaciones_admin_activa_unique_idx
on public.vinculaciones (id_administrador)
where activa = true;

create unique index if not exists vinculaciones_device_unique_idx
on public.vinculaciones (dispositivo_id);

alter table public.vinculaciones enable row level security;

drop policy if exists "vinculaciones_select_admin" on public.vinculaciones;
create policy "vinculaciones_select_admin"
on public.vinculaciones
for select
to authenticated
using (id_administrador = auth.uid());

create or replace function public.link_device_by_code(
  link_code text,
  device_id text,
  display_name text default 'Usuario mayor'
)
returns public.usuarios
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_code text := upper(replace(coalesce(link_code, ''), '-', ''));
  normalized_device text := trim(coalesce(device_id, ''));
  admin_row public.usuarios%rowtype;
  resolved_name text := coalesce(nullif(trim(display_name), ''), 'Usuario mayor');
begin
  if normalized_code = '' then
    raise exception 'Código de vinculación vacío';
  end if;

  if normalized_device = '' then
    raise exception 'Dispositivo inválido';
  end if;

  select *
  into admin_row
  from public.usuarios
  where codigo_vinculacion = normalized_code
    and rol = 'administrador'
  order by created_at asc
  limit 1;

  if admin_row.id is null then
    raise exception 'Código de vinculación no válido';
  end if;

  update public.vinculaciones
  set activa = false,
      updated_at = timezone('utc', now())
  where dispositivo_id = normalized_device
    and id_administrador <> admin_row.id;

  insert into public.vinculaciones (
    id_administrador,
    codigo_vinculacion,
    dispositivo_id,
    nombre_usuario_mayor,
    activa,
    created_at,
    updated_at
  )
  values (
    admin_row.id,
    normalized_code,
    normalized_device,
    resolved_name,
    true,
    timezone('utc', now()),
    timezone('utc', now())
  )
  on conflict (dispositivo_id)
  do update set
    id_administrador = excluded.id_administrador,
    codigo_vinculacion = excluded.codigo_vinculacion,
    nombre_usuario_mayor = excluded.nombre_usuario_mayor,
    activa = true,
    updated_at = timezone('utc', now());

  return admin_row;
end;
$$;

revoke all on function public.link_device_by_code(text, text, text) from public;
grant execute on function public.link_device_by_code(text, text, text) to anon;
grant execute on function public.link_device_by_code(text, text, text) to authenticated;
