do $$
<<database_object_check>>																													 
begin

	--drop view if exists
	if exists
	(
		SELECT 1 
		FROM   pg_views
		WHERE  schemaname = 'public'
		AND    viewname = 'vw_generate_matches'
	)
	then

		--drop view statement
		drop view public.vw_generate_matches;

	end if;

	--drop table if exists
	if exists
	(
		SELECT 1 
		FROM   pg_catalog.pg_class c
		JOIN   pg_catalog.pg_namespace n ON n.oid = c.relnamespace
		WHERE  n.nspname = 'public'
		AND    c.relname = 'stage_matching_data'
		AND    c.relkind = 'r'    -- only tables
	)
	then

		--drop table statement
		drop table public.stage_matching_data;

	end if;

	--drop table if exists
	if exists
	(
		SELECT 1 
		FROM   pg_catalog.pg_class c
		JOIN   pg_catalog.pg_namespace n ON n.oid = c.relnamespace
		WHERE  n.nspname = 'public'
		AND    c.relname = 'user_matching_details'
		AND    c.relkind = 'r'    -- only tables
	)
	then

		--drop table statement
		drop table public.user_matching_details;

	end if;		

	--drop table if exists
	if exists
	(
		SELECT 1 
		FROM   pg_catalog.pg_class c
		JOIN   pg_catalog.pg_namespace n ON n.oid = c.relnamespace
		WHERE  n.nspname = 'public'
		AND    c.relname = 'user_rejection_details'
		AND    c.relkind = 'r'    -- only tables
	)
	then

		--drop table statement
		drop table public.user_rejection_details;

	end if;	

	--drop table if exists
	if exists
	(
		SELECT 1 
		FROM   pg_catalog.pg_class c
		JOIN   pg_catalog.pg_namespace n ON n.oid = c.relnamespace
		WHERE  n.nspname = 'public'
		AND    c.relname = 'user_details'
		AND    c.relkind = 'r'    -- only tables
	)
	then

		--drop table statement
		drop table public.user_details;

	end if;																													 	
																													 
end
database_object_check $$;

--===========================================================================

-------------------------------------------------------------all table scripts : start-------------------------------------------------------------

--===========================================================================

-- Table: public.stage_matching_data

-- DROP TABLE public.stage_matching_data;

CREATE TABLE public.stage_matching_data
(
    id serial,
    display_name character varying(100) COLLATE pg_catalog."default",
    age integer,
    job_title character varying(100) COLLATE pg_catalog."default",
    height_in_cm integer,
    city_name character varying(100) COLLATE pg_catalog."default",
    city_lat numeric(9,6),
    city_lon numeric(9,6),
    main_photo character varying(500) COLLATE pg_catalog."default",
    pokemon_catch_rate numeric(4,2),
    cats_owned integer,
    likes_cats boolean,
    religion character varying(10) COLLATE pg_catalog."default", 
	created_on timestamp not null default current_timestamp,
	created_by varchar(100) not null default current_user,
	updated_on timestamp null,
	updated_by varchar(100) null,	
    CONSTRAINT pk_stage_matching_data_id PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.stage_matching_data
    OWNER to postgres;
	
--===========================================================================

-- Table: public.user_details

-- DROP TABLE public.user_details;

CREATE TABLE public.user_details
(
    id serial,
    display_name character varying(100) COLLATE pg_catalog."default",
    age integer,
    job_title character varying(100) COLLATE pg_catalog."default",
    height_in_cm integer,
    city_name character varying(100) COLLATE pg_catalog."default",
    city_lat numeric(9,6),
    city_lon numeric(9,6),
    main_photo character varying(500) COLLATE pg_catalog."default",
    pokemon_catch_rate numeric(4,2),
    cats_owned integer,
    likes_cats boolean,
    religion character varying(10) COLLATE pg_catalog."default",
	created_on timestamp not null default current_timestamp,
	created_by varchar(100) not null default current_user,
	updated_on timestamp null,
	updated_by varchar(100) null,	
    CONSTRAINT pk_user_details_id PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.user_details
    OWNER to postgres;
	
--===========================================================================

-- Table: public.user_matching_details

-- DROP TABLE public.user_matching_details;

CREATE TABLE public.user_matching_details
(
    id serial,
    user_id integer,
    user_matching_id integer,
    matching_result text COLLATE pg_catalog."default",
    current_flag integer,
	created_on timestamp not null default current_timestamp,
	created_by varchar(100) not null default current_user,
	updated_on timestamp null,
	updated_by varchar(100) null,
    CONSTRAINT pk_user_matching_details_id PRIMARY KEY (id),
    CONSTRAINT fk_user_matching_details_user_id FOREIGN KEY (user_id)
        REFERENCES public.user_details (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_user_matching_details_user_matching_id FOREIGN KEY (user_matching_id)
        REFERENCES public.user_details (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.user_matching_details
    OWNER to postgres;
	
-------------------------------------------------------------all table scripts : end-------------------------------------------------------------

-------------------------------------------------------all stored procedure scripts : start------------------------------------------------------
							  

							  
--()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()
--{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]




-- FUNCTION: public.generate_matches(integer)

-- DROP FUNCTION public.generate_matches(integer);

CREATE OR REPLACE FUNCTION public.generate_matches(
	distance_criteria integer)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
--variable declaration
declare	distance_criteria_value integer := null;
begin

	/*-------------------------------------------------------------------------------------------------------------------------------------------*/
	
	--temp table to store the matching data
	create temp table tmp_user_matching_details
	(
		user_id 			integer,
		user_matching_id 	integer,
		matching_result 	text COLLATE pg_catalog."default"
	);
	
	/*-------------------------------------------------------------------------------------------------------------------------------------------*/
	
	--assigning input parameter to a variable
	distance_criteria_value := distance_criteria;
										   
	/*-------------------------------------------------------------------------------------------------------------------------------------------*/
	
	--generating matching data
	insert into tmp_user_matching_details
	(
		user_id,
		user_matching_id,
		matching_result
	)
	select	user_id,
			user_matching_id,
			match_result
	from	(
				select	
				base.id as user_id,
				comp.id as user_matching_id,
				(
					case
						when 	(abs(base.age - comp.age) <= 5) 
						and		(
									case	when ((base.pokemon_catch_rate * 100) > 70 or (comp.pokemon_catch_rate * 100) > 70)
											then abs(base.pokemon_catch_rate * 100 - comp.pokemon_catch_rate * 100) < 15
											else abs(base.pokemon_catch_rate * 100 - comp.pokemon_catch_rate * 100) < 30
									end
								)
						and		(base.religion = comp.religion) 
						and		(base.likes_cats = comp.likes_cats)
						then 	'Match'
						else 	'Reject'
					end 
				) as match_result
				from 	public.user_details base, public.user_details comp
				where 	base.id <> comp.id
				and		floor(gc_dist(base.city_lat, base.city_lon, comp.city_lat, comp.city_lon)) <= distance_criteria_value
			)
			as tbl
	order by user_id, user_matching_id;
											   
	/*-------------------------------------------------------------------------------------------------------------------------------------------*/

	--making active matching data inactive due to the change in matching criteria						  	
	if exists
	(
		select 	1
		from 	tmp_user_matching_details as tumd
		join	public.user_matching_details as umd
		on 		umd.user_id = tumd.user_id
		and 	umd.user_matching_id = tumd.user_matching_id
		where 	umd.matching_result <> tumd.matching_result
		and		umd.current_flag = 1
		and		tumd.matching_result = 'Reject'
		and		umd.matching_result = 'Match'
	)
	then

		update 	public.user_matching_details as umd
		set 	current_flag = 0,
				updated_on = current_timestamp,
				updated_by = current_user
		from 	tmp_user_matching_details as tumd
		where 	umd.user_id = tumd.user_id
		and 	umd.user_matching_id = tumd.user_matching_id
		and 	umd.matching_result <> tumd.matching_result
		and		umd.current_flag = 1
		and		tumd.matching_result = 'Reject'
		and		umd.matching_result = 'Match';

	end if;

	--################################################################################################

	--making inactive matching data active due to the change in matching criteria
	if exists
	(
		select 	1
		from 	tmp_user_matching_details as tumd
		join	public.user_matching_details as umd
		on 		umd.user_id = tumd.user_id
		and 	umd.user_matching_id = tumd.user_matching_id
		and		tumd.matching_result = umd.matching_result
		where	tumd.matching_result = 'Match'
		and		umd.matching_result = 'Match'
		and		umd.current_flag = 0
	)
	then

		update 	public.user_matching_details as umd
		set 	current_flag = 1,
				updated_on = current_timestamp,
				updated_by = current_user
		from 	tmp_user_matching_details as tumd
		where	umd.user_id = tumd.user_id
		and 	umd.user_matching_id = tumd.user_matching_id
		and		tumd.matching_result = umd.matching_result
		and		tumd.matching_result = 'Match'
		and		umd.matching_result = 'Match'
		and		umd.current_flag = 0;					  
							  
	end if;

	--################################################################################################

	--inserting new matching data					  	
	if exists
	(
		select 		1
		from 		tmp_user_matching_details as tumd
		left join	public.user_matching_details as umd
		on 			umd.user_id = tumd.user_id
		and 		umd.user_matching_id = tumd.user_matching_id
		where		tumd.matching_result = 'Match'
		and			umd.user_id is null
		and			umd.user_matching_id is null
	)
	then

		insert into public.user_matching_details
		(
			user_id,
			user_matching_id,
			matching_result,
			current_flag
		)
		select		user_id,
					user_matching_id,
					matching_result,
					1 as current_flag
		from		(
						select		row_number() over (partition by tumd.user_id) as row_id,
									tumd.user_id,
									tumd.user_matching_id,
									tumd.matching_result
						from 		tmp_user_matching_details as tumd
						left join	public.user_matching_details as umd
						on 			umd.user_id = tumd.user_id
						and 		umd.user_matching_id = tumd.user_matching_id
						where		tumd.matching_result = 'Match'
						and			umd.user_id is null
						and			umd.user_matching_id is null
					)
					as tbl
		where		row_id <= 2;

	end if;

	--################################################################################################	
											   
	/*-------------------------------------------------------------------------------------------------------------------------------------------*/
   
	--drop temp temp table
	drop table tmp_user_matching_details;

	--return statement
	return 1;
   
end
; $BODY$;

ALTER FUNCTION public.generate_matches(integer)
    OWNER TO postgres;
							  

							  
--()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()
--{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
							  
							  

-- FUNCTION: public.reject_matches()

-- DROP FUNCTION public.reject_matches();

CREATE OR REPLACE FUNCTION public.reject_matches(
	)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
begin

	/*-------------------------------------------------------------------------------------------------------------------------------------------*/
	
	--temp table to store the rejection data
	create temp table tmp_user_rejection_details
	(
		user_id 			integer,
		user_matching_id 	integer,
		matching_result 	text COLLATE pg_catalog."default"
	);
										   
	/*-------------------------------------------------------------------------------------------------------------------------------------------*/
	
	--creating rejection list
	insert into tmp_user_rejection_details
	(
		user_id,
		user_matching_id,
		matching_result
	)
	select	user_id,
			user_matching_id,
			match_result
	from	(
				select	
				base.id as user_id,
				comp.id as user_matching_id,
				(
					case
						when 	(abs(base.age - comp.age) <= 5) 
						and		(
									case	when ((base.pokemon_catch_rate * 100) > 70 or (comp.pokemon_catch_rate * 100) > 70)
											then abs(base.pokemon_catch_rate * 100 - comp.pokemon_catch_rate * 100) < 15
											else abs(base.pokemon_catch_rate * 100 - comp.pokemon_catch_rate * 100) < 30
									end
								)
						and		(base.religion = comp.religion) 
						and		(base.likes_cats = comp.likes_cats)
						then 	'Match'
						else 	'Reject'
					end 
				) as match_result
				from 	public.user_details base, public.user_details comp
				where 	base.id <> comp.id
				--and		floor(gc_dist(base.city_lat, base.city_lon, comp.city_lat, comp.city_lon)) <= distance_criteria_value
			)
			as tbl
	order by user_id, user_matching_id;
											   
	/*-------------------------------------------------------------------------------------------------------------------------------------------*/

	--updating the main rejection list
	if exists
	(
		select 	1
		from 	tmp_user_rejection_details as tumd
		join	public.user_rejection_details as umd
		on 		umd.user_id = tumd.user_id
		and 	umd.user_matching_id = tumd.user_matching_id
		where 	umd.matching_result <> tumd.matching_result
		and		umd.current_flag = 1
		and		tumd.matching_result = 'Match'
		and		umd.matching_result = 'Reject'
	)
	then

		update 	public.user_rejection_details as umd
		set 	current_flag = 0,
				updated_on = current_timestamp,
				updated_by = current_user
		from 	tmp_user_rejection_details as tumd
		where 	umd.user_id = tumd.user_id
		and 	umd.user_matching_id = tumd.user_matching_id
		and 	umd.matching_result <> tumd.matching_result
		and		umd.current_flag = 1
		and		tumd.matching_result = 'Match'
		and		umd.matching_result = 'Reject';

	end if;

	--################################################################################################

	--making inactive rejected data active due to the change in matching criteria
	if exists
	(
		select 	1
		from 	tmp_user_rejection_details as tumd
		join	public.user_rejection_details as umd
		on 		umd.user_id = tumd.user_id
		and 	umd.user_matching_id = tumd.user_matching_id
		and		tumd.matching_result = umd.matching_result
		where	tumd.matching_result = 'Reject'
		and		umd.matching_result = 'Reject'
		and		umd.current_flag = 0
	)
	then

		update 	public.user_rejection_details as umd
		set 	current_flag = 1,
				updated_on = current_timestamp,
				updated_by = current_user
		from 	tmp_user_rejection_details as tumd
		where	umd.user_id = tumd.user_id
		and 	umd.user_matching_id = tumd.user_matching_id
		and		tumd.matching_result = umd.matching_result
		and		tumd.matching_result = 'Reject'
		and		umd.matching_result = 'Reject'
		and		umd.current_flag = 0;					  
							  
	end if;

	--################################################################################################

	--inserting new rejection records
	if exists
	(
		select 		1
		from 		tmp_user_rejection_details as tumd
		left join	public.user_rejection_details as umd
		on 			umd.user_id = tumd.user_id
		and 		umd.user_matching_id = tumd.user_matching_id
		where		tumd.matching_result = 'Reject'
		and			umd.user_id is null
		and			umd.user_matching_id is null
	)
	then

		insert into public.user_rejection_details
		(
			user_id,
			user_matching_id,
			matching_result,
			current_flag
		)
		select		user_id,
					user_matching_id,
					matching_result,
					1 as current_flag
		from		(
						select		tumd.user_id,
									tumd.user_matching_id,
									tumd.matching_result
						from 		tmp_user_rejection_details as tumd
						left join	public.user_rejection_details as umd
						on 			umd.user_id = tumd.user_id
						and 		umd.user_matching_id = tumd.user_matching_id
						where		tumd.matching_result = 'Reject'
						and			umd.user_id is null
						and			umd.user_matching_id is null
					)
					as tbl;

	end if;

	--################################################################################################	
											   
	/*-------------------------------------------------------------------------------------------------------------------------------------------*/
   
	--drop temp temp table
	drop table tmp_user_rejection_details;

	--return statement
	return 1;
   
end
; $BODY$;

ALTER FUNCTION public.reject_matches()
    OWNER TO postgres;
							  

							  
--()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()
--{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]



-- FUNCTION: public.gc_dist(double precision, double precision, double precision, double precision)

-- DROP FUNCTION public.gc_dist(double precision, double precision, double precision, double precision);

CREATE OR REPLACE FUNCTION public.gc_dist(
	_lat1 double precision,
	_lon1 double precision,
	_lat2 double precision,
	_lon2 double precision)
    RETURNS double precision
    LANGUAGE 'sql'

    COST 100
    IMMUTABLE 
AS $BODY$
  select ACOS(SIN($1)*SIN($3)+COS($1)*COS($3)*COS($4-$2))*6371;
$BODY$;

ALTER FUNCTION public.gc_dist(double precision, double precision, double precision, double precision)
    OWNER TO postgres;

							  

							  
--()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()
--{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]



-- FUNCTION: public.get_matches(character varying)

-- DROP FUNCTION public.get_matches(character varying);

CREATE OR REPLACE FUNCTION public.get_matches(
	username character varying)
    RETURNS TABLE(user_name character varying, user_age integer, user_job_title character varying, user_height_in_cm integer, user_city_name character varying, user_city_lat numeric, user_city_lon numeric, user_pokemon_catch_rate numeric, user_cates_owned integer, user_likes_cats boolean, user_religion character varying, matching_user_name character varying, matching_user_age integer, matching_user_job_title character varying, matching_user_height_in_cm integer, matching_user_city_name character varying, matching_user_city_lat numeric, matching_user_city_lon numeric, matching_user_pokemon_catch_rate numeric, matching_user_cates_owned integer, matching_user_likes_cats boolean, matching_user_religion character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$

	--variable declaration
	declare error_message varchar(1000) := null;

begin

	--to check the existence of the user_name
	if not exists
	(
		select 1 from public.user_details where display_name = username
	)
	then

		--error message setup
		error_message := 'Error : User ' || username || ' does not exist';

		--raise error manually
		raise exception '%',error_message;

		--return
		return next;
														 
	else

		--return data
		return query
		select		ud.display_name				as user_name,
					ud.age						as user_age,
					ud.job_title				as user_job_title,
					ud.height_in_cm				as user_height_in_cm,
					ud.city_name				as user_city_name,
					ud.city_lat					as user_city_lat,
					ud.city_lon					as user_city_lon,
					ud.pokemon_catch_rate		as user_pokemon_catch_rate,
					ud.cats_owned				as user_cats_owned,
					ud.likes_cats				as user_likes_cats,
					ud.religion					as user_religion,
														 
					ud1.display_name			as matching_user_name,
					ud1.age						as matching_user_age,
					ud1.job_title				as matching_user_job_title,
					ud1.height_in_cm			as matching_user_height_in_cm,
					ud1.city_name				as matching_user_city_name,
					ud1.city_lat				as matching_user_city_lat,
					ud1.city_lon				as matching_user_city_lon,
					ud1.pokemon_catch_rate		as matching_user_pokemon_catch_rate,
					ud1.cats_owned				as matching_user_cats_owned,
					ud1.likes_cats				as matching_user_likes_cats,
					ud1.religion				as matching_user_religion
														 
		from		public.user_details as ud
		inner join	public.user_matching_details as umd
		on			ud.id = umd.user_id
		inner join	public.user_details as ud1
		on			umd.user_matching_id = ud1.id
		where		ud.display_name = username
		and 		umd.current_flag = 1;

	end if;

end
; $BODY$;

ALTER FUNCTION public.get_matches(character varying)
    OWNER TO postgres;

							  

							  
--()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()
--{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]


							  
-------------------------------------------------------all stored procedure scripts : end--------------------------------------------------------

---------------------------------------------------------view script for testing : start---------------------------------------------------------
							  
-- View: public.vw_generate_matches

-- DROP VIEW public.vw_generate_matches;

CREATE OR REPLACE VIEW public.vw_generate_matches AS
 SELECT base.id AS candidate_id,
    base.display_name AS candidate_name,
    base.age AS candidate_age,
	base.city_name AS candidate_city_name,
	base.city_lat AS candidate_city_lat,
	base.city_lon AS candidate_city_lon,
    base.pokemon_catch_rate AS candidate_pokemon_catch_rate,
	base.likes_cats AS candidate_likes_cats,
    base.cats_owned AS candidate_cats_owned,
    base.religion AS candidate_religion,
    comp.id AS matching_id,
    comp.display_name AS matching_name,
    comp.age AS matching_age,
	comp.city_name AS matching_city_name,
	comp.city_lat AS matching_city_lat,
	comp.city_lon AS matching_city_lon,
    comp.pokemon_catch_rate AS matching_pokemon_catch_rate,
	comp.likes_cats AS matching_likes_cats,
    comp.cats_owned AS matching_cats_owned,
    comp.religion AS matching_religion,
	floor(gc_dist(base.city_lat, base.city_lon, comp.city_lat, comp.city_lon)) AS distance_in_km,
	
	CASE
		--===============================================================================================================================
		WHEN 
		abs(base.age - comp.age) <= 5 
			AND
		CASE
			WHEN (base.pokemon_catch_rate * 100::numeric) > 70::numeric OR (comp.pokemon_catch_rate * 100::numeric) > 70::numeric 
			THEN abs(base.pokemon_catch_rate * 100::numeric - comp.pokemon_catch_rate * 100::numeric) < 15::numeric
		ELSE abs(base.pokemon_catch_rate * 100::numeric - comp.pokemon_catch_rate * 100::numeric) < 30::numeric
		END 
			AND 
		base.religion::text = comp.religion::text 
			AND
		base.likes_cats = comp.likes_cats
		THEN 'Match'

		ELSE 'Reject'

	END AS match_result	
		
   FROM stage_matching_data base,
    stage_matching_data comp
  WHERE base.id <> comp.id
  ORDER BY base.id, comp.id;

ALTER TABLE public.vw_generate_matches
    OWNER TO postgres;

---------------------------------------------------------view script for testing : end-----------------------------------------------------------



