-- Normalise phrases on the way in, whoever writes them (CSV import, table
-- editor, submit_phrase): trim text, context and author, and turn a blank
-- author into null. Some importers store empty cells as '' instead of null,
-- which would otherwise trip the author checks for every peñista row.

create function private.normalize_phrase() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.text := btrim(new.text);
  new.context := btrim(new.context);
  new.author := nullif(btrim(new.author), '');
  return new;
end
$$;

revoke execute on function private.normalize_phrase() from public, anon, authenticated;

create trigger phrases_normalize
before insert or update of text, context, author on public.phrases
for each row execute function private.normalize_phrase();
