-- Classement des défis ZooLife (12/11/2026). À coller dans Supabase : SQL Editor > New query > Run.
-- Avant : Authentication > Sign In / Providers > activer « Allow anonymous sign-ins » (chaque joueur reçoit un
-- identifiant anonyme, sans e-mail ni mot de passe).
--
-- Principe : les joueurs ne lisent jamais les tables directement (aucune règle de lecture). Tout passe par des fonctions :
--   soumettre_score : garde le meilleur score de chaque joueur par défi, avec le replay de cette partie ;
--   classement      : rang du joueur, nombre de participants, top 10 avec pseudos (visible par tous ; les joueurs hors
--                     du top 10 ne sont jamais montrés aux autres, chacun ne voit que sa propre ligne) ;
--   replay_semaine_precedente : le replay du vainqueur du défi de la semaine passée, une fois la semaine finie.
-- Les autres replays ne se lisent que depuis le tableau de bord Supabase (Table Editor), pour vérifier les scores.

create table if not exists public.scores (
  joueur      uuid        not null default auth.uid(),
  defi        text        not null,
  pseudo      text        not null,
  score       numeric     not null,
  version     text        not null,
  replay      jsonb       not null,
  verifie     boolean     not null default false,   -- coché à la main après avoir rejoué la partie
  exclu       boolean     not null default false,   -- score triché : retiré du classement
  cree_le     timestamptz not null default now(),
  primary key (joueur, defi)
);

alter table public.scores enable row level security;
-- Aucune règle (policy) : ni lecture ni écriture directes pour les joueurs.

-- Un défi de la semaine s'appelle « semaine_<n> », n = semaines depuis le lundi 29/12/1969 (comme dans le jeu).
create or replace function public.semaine_courante() returns int
language sql stable as $$
  select floor((floor(extract(epoch from now()) / 86400) + 3) / 7)::int
$$;

create or replace function public.soumettre_score(p_defi text, p_pseudo text, p_score numeric, p_version text, p_replay jsonb)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  ancien numeric;
begin
  if auth.uid() is null then
    raise exception 'non connecté';
  end if;
  if length(p_pseudo) < 3 or length(p_pseudo) > 16 or p_score < 0 or p_score > 2000
     or length(p_defi) > 40 or pg_column_size(p_replay) > 2000000 then
    raise exception 'score refusé';
  end if;
  -- Un défi de la semaine ne se joue que pendant sa semaine.
  if p_defi like 'semaine\_%' and substring(p_defi from 9)::int <> semaine_courante() then
    raise exception 'défi terminé';
  end if;
  select score into ancien from scores where joueur = auth.uid() and defi = p_defi;
  if ancien is null then
    insert into scores (joueur, defi, pseudo, score, version, replay) values (auth.uid(), p_defi, p_pseudo, p_score, p_version, p_replay);
  elsif p_score > ancien then
    update scores set pseudo = p_pseudo, score = p_score, version = p_version, replay = p_replay, verifie = false, cree_le = now()
      where joueur = auth.uid() and defi = p_defi;
  else
    update scores set pseudo = p_pseudo where joueur = auth.uid() and defi = p_defi;  -- le pseudo peut changer
  end if;
  return classement(p_defi);
end $$;

create or replace function public.classement(p_defi text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  mon_score numeric;
  mon_rang  int;
  total     int;
  top       jsonb;
begin
  select count(*) into total from scores where defi = p_defi and not exclu;
  select score into mon_score from scores where joueur = auth.uid() and defi = p_defi and not exclu;
  if mon_score is not null then
    select count(*) + 1 into mon_rang from scores where defi = p_defi and not exclu and score > mon_score;
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
           'rang', rang,
           'score', score,
           'moi', joueur = auth.uid(),
           'pseudo', pseudo)
         order by rang), '[]'::jsonb)
    into top
    from (select joueur, pseudo, score, rank() over (order by score desc) as rang
            from scores where defi = p_defi and not exclu
            order by score desc, cree_le asc limit 10) t;
  return jsonb_build_object('rang', mon_rang, 'score', mon_score, 'total', total, 'top', top);
end $$;

-- Le replay du meilleur joueur d'un défi de la semaine, seulement une fois cette semaine passée.
create or replace function public.replay_semaine_precedente()
returns jsonb
language sql security definer set search_path = public as $$
  select jsonb_build_object('defi', defi, 'pseudo', pseudo, 'score', score, 'replay', replay)
    from scores
   where defi = 'semaine_' || (semaine_courante() - 1) and not exclu
   order by score desc, cree_le asc
   limit 1
$$;

-- Le vainqueur de la semaine passée, sans son replay (note de service du menu).
create or replace function public.vainqueur_semaine_precedente()
returns jsonb
language sql security definer set search_path = public as $$
  select jsonb_build_object('defi', defi, 'pseudo', pseudo, 'score', score)
    from scores
   where defi = 'semaine_' || (semaine_courante() - 1) and not exclu
   order by score desc, cree_le asc
   limit 1
$$;

revoke all on function public.soumettre_score(text, text, numeric, text, jsonb) from public, anon;
revoke all on function public.classement(text) from public, anon;
revoke all on function public.replay_semaine_precedente() from public, anon;
revoke all on function public.vainqueur_semaine_precedente() from public, anon;
grant execute on function public.soumettre_score(text, text, numeric, text, jsonb) to authenticated;
grant execute on function public.classement(text) to authenticated;
grant execute on function public.replay_semaine_precedente() to authenticated;
grant execute on function public.vainqueur_semaine_precedente() to authenticated;
