create extension if not exists pgcrypto;

alter table public.usuarios
add column if not exists id_administrador uuid references public.usuarios (id) on delete set null;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'usuarios'
      and column_name = 'id'
      and data_type = 'uuid'
  ) then
    execute 'alter table public.usuarios alter column id set default gen_random_uuid()';
  end if;
end $$;

create index if not exists usuarios_codigo_vinculacion_idx
on public.usuarios (codigo_vinculacion);

create index if not exists usuarios_id_administrador_idx
on public.usuarios (id_administrador);

create unique index if not exists usuarios_un_admin_un_mayor_idx
on public.usuarios (id_administrador)
where rol = 'mayor';

create or replace function public.can_access_care_user(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuarios u
    where u.id = target_user_id
      and (
        u.id = auth.uid()
        or u.id_administrador = auth.uid()
      )
  );
$$;

alter table public.usuarios enable row level security;
alter table public.medicamentos enable row level security;
alter table public.citas enable row level security;
alter table public.tomas enable row level security;
alter table public.alertas enable row level security;

drop policy if exists "usuarios_select_self_or_linked" on public.usuarios;
create policy "usuarios_select_self_or_linked"
on public.usuarios
for select
to authenticated
using (
  id = auth.uid()
  or id_administrador = auth.uid()
);

drop policy if exists "usuarios_insert_linked_mayor" on public.usuarios;
create policy "usuarios_insert_linked_mayor"
on public.usuarios
for insert
to authenticated
with check (
  rol = 'mayor'
  and id_administrador = auth.uid()
);

drop policy if exists "usuarios_update_self_or_linked" on public.usuarios;
create policy "usuarios_update_self_or_linked"
on public.usuarios
for update
to authenticated
using (
  id = auth.uid()
  or id_administrador = auth.uid()
)
with check (
  id = auth.uid()
  or id_administrador = auth.uid()
);

drop policy if exists "medicamentos_access_linked_user" on public.medicamentos;
create policy "medicamentos_access_linked_user"
on public.medicamentos
for all
to authenticated
using (public.can_access_care_user(id_usuario))
with check (public.can_access_care_user(id_usuario));

drop policy if exists "citas_access_linked_user" on public.citas;
create policy "citas_access_linked_user"
on public.citas
for all
to authenticated
using (public.can_access_care_user(id_usuario))
with check (public.can_access_care_user(id_usuario));

drop policy if exists "tomas_access_linked_user" on public.tomas;
create policy "tomas_access_linked_user"
on public.tomas
for all
to authenticated
using (public.can_access_care_user(id_usuario))
with check (public.can_access_care_user(id_usuario));

drop policy if exists "alertas_access_linked_user" on public.alertas;
create policy "alertas_access_linked_user"
on public.alertas
for all
to authenticated
using (public.can_access_care_user(id_usuario))
with check (public.can_access_care_user(id_usuario));
