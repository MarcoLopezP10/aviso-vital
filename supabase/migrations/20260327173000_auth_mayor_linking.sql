drop policy if exists "usuarios_insert_linked_mayor" on public.usuarios;
create policy "usuarios_insert_self_or_linked_mayor"
on public.usuarios
for insert
to authenticated
with check (
  id = auth.uid()
  or (rol = 'mayor' and id_administrador = auth.uid())
);

create or replace function public.link_authenticated_user_by_code(link_code text)
returns public.usuarios
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_code text := upper(replace(coalesce(link_code, ''), '-', ''));
  admin_row public.usuarios%rowtype;
  current_row public.usuarios%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Debes iniciar sesión antes de vincular un código';
  end if;

  if normalized_code = '' then
    raise exception 'Código de vinculación vacío';
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

  update public.usuarios
  set
    rol = 'mayor',
    id_administrador = admin_row.id,
    ultima_sincronizacion = timezone('utc', now())
  where id = auth.uid()
  returning *
  into current_row;

  if current_row.id is null then
    raise exception 'No se pudo actualizar el perfil del usuario mayor';
  end if;

  return current_row;
end;
$$;

revoke all on function public.link_authenticated_user_by_code(text) from public;
grant execute on function public.link_authenticated_user_by_code(text) to authenticated;
