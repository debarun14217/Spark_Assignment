/*******************************************************************************************************************************/
----------------------------------------------------1st scenario : start--------------------------------------------------------  
/*******************************************************************************************************************************/

--Test script to check the data population from data.json data file to database table

--step 1: execute this below statement to clean-up public.stage_matching_data
truncate table public.stage_matching_data restart identity cascade; 

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 2: this below query should not return any record
select * from public.stage_matching_data; 
/*
expected result :-
===================
It will return nothing.
*/

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 3: execute python script through jupyter notebook and you should receive the below message - 
/*
expected result :-
==================
Total incoming row count :  25
 
Total inserted row count :  25
 
Success : All the rows are inserted from json data file to the database table successfully
*/

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 4: check the data and the row count should be 25.
select * from public.stage_matching_data; --25
select count(*) from public.stage_matching_data; --25
/*
expected result :-
==================
It should return 25 as row count.
*/

/*******************************************************************************************************************************/
----------------------------------------------------1st scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/




--===================================================================================================================================================

/*
Initially I planned to create a function to insert data from public.stage_matching_data table to public.user_details table by comparing the data of 
column "display_name" from both tables. But I found a duplicate name and that 'Caroline'. No other combination was a perfect choice for data comparison 
to insert data from stage to the main table. Perhaps an "id" key (from application) or "unique identifier" key (from application) or 
"SSN" (social security number) or "passport number" key in the json data set for ach record would be helpful.
*/

truncate table public.user_details restart identity cascade;

insert into public.user_details(
	display_name, age, job_title, height_in_cm, city_name, city_lat, city_lon, main_photo, pokemon_catch_rate, cats_owned, likes_cats, religion)
select display_name, age, job_title, height_in_cm, city_name, city_lat, city_lon, main_photo, pokemon_catch_rate, cats_owned, likes_cats, religion 
	from public.stage_matching_data;

select * from public.user_details;

--===================================================================================================================================================




/*******************************************************************************************************************************/
----------------------------------------------------2nd scenario : start----------------------------------------------------------  
/*******************************************************************************************************************************/

--Test script to check the data population related to matching data

--step 1: execute view to check matching data for testing
select * from public.vw_generate_matches where match_result = 'Match' and candidate_id = 5;
/*
expected result:-
=================
total five rows will be returned and the matching ids with "candidate_id" = 5 are 6,8,12,13,15
*/

--step 2: executing generate_matches(20000) where 20000 is getting used as a input parameter for distance adjustment between two users
select * from public.user_matching_details where user_id = 5 and Current_flag = 1;
/*
expected result:-
=================
no record
*/

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--1st time
select public.generate_matches(20000);
/*
expected result:-
=================
two records should be added in public.user_matching_details for user_id = 5
*/

select * from public.user_matching_details where user_id = 5 and Current_flag = 1;
/*
expected result:-
=================
The query should return 2 rows.
*/

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--2nd time
select public.generate_matches(20000);
/*
expected result:-
=================
Another two records should be added in public.user_matching_details for user_id = 5
*/

select * from public.user_matching_details where user_id = 5 and Current_flag = 1;
/*
expected result:-
=================
The query should return 4 rows.
*/

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--3rd time
select public.generate_matches(20000);
/*
expected result:-
=================
Another one records should be added in public.user_matching_details for user_id = 5
*/

select * from public.user_matching_details where user_id = 5 and Current_flag = 1;
/*
expected result:-
=================
The query should return 5 rows.
*/

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--4th time
select public.generate_matches(20000);
/*
expected result:-
=================
no record should be added in public.user_matching_details for user_id = 5
*/

select * from public.user_matching_details where user_id = 5 and Current_flag = 1;
/*
expected result:-
=================
The query should return 5 rows.
*/

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 3: comparing data with view data
select 	umd.user_id,umd.user_matching_id as matching_data_from_table,vgm.matching_id as matching_data_from_test_view,
		case when umd.user_matching_id = vgm.matching_id then 'Success' else 'failure' end as test_result
from	public.user_matching_details as umd
join	public.vw_generate_matches as vgm
on		umd.user_id = vgm.candidate_id
and		umd.user_matching_id = vgm.matching_id
where	umd.user_id = 5 and umd.Current_flag = 1;
/*
expected result :-
===================
The above query should return five rows with 'Success' message.
*/

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 4: Calling get_matches() function to get the records based on username
select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return five rows.
*/


/*******************************************************************************************************************************/
----------------------------------------------------2nd scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/







--#######################################################################################################################################################








/*******************************************************************************************************************************/
----------------------------------------------------3rd scenario : start----------------------------------------------------------  
/*******************************************************************************************************************************/

--Test script to check the data population related to rejected data

--step 1: Checking the user_rejection_details table for records
select * from public.user_rejection_details;
/*
expected result :-
===================
The above query should not return any record.
*/

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 2: Calling reject_matches() function to generate the rejection list
select reject_matches();

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 3: Checking the user_rejection_details table again for records
select * from public.user_rejection_details;
/*
expected result :-
===================
The above query should return records now.
*/


/*******************************************************************************************************************************/
----------------------------------------------------3rd scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/







--#######################################################################################################################################################







/*******************************************************************************************************************************/
----------------------------------------------------4th scenario : start----------------------------------------------------------  
/*******************************************************************************************************************************/

--Testing data by changing criteria value (age) of a record which exists in matching list and pushing it into rejected list
--and again modifying the value of age to bring the same record back to matching list from rejected list 

--step 1: checking matching records for username Maria
select * from public.get_matches('Maria'); 
/*
expected result :-
===================
The above query will return 5 record.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 2: checking data in the rejection list related to ('Maria','Tracy')
select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should not return any record.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 3: checking data in the matching list related to ('Maria','Tracy')
select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 4: Modifying Tracy's age from 39 to 49 and execute generate_matches() and reject_matches() to update matching list and rejection list
update public.user_details set age = 49 where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should not return record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 4 records and no record should be there related to 'Tracy'.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 5: Modifying Tracy's age from 49 to 39 and execute generate_matches() and reject_matches() to update matching list and rejection list
update public.user_details set age = 39 where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return no record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 5 records.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*******************************************************************************************************************************/
----------------------------------------------------4th scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/







--#######################################################################################################################################################








/*******************************************************************************************************************************/
----------------------------------------------------5th scenario : start----------------------------------------------------------  
/*******************************************************************************************************************************/

--Testing data by changing criteria value (likes_cats) of a record which exists in matching list and pushing it into rejected list
--and again modifying the value of likes_cats to bring the same record back to matching list from rejected list 

--checking matching data for 'Maria'
select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 5 records.
*/ 

--step 1: Modifying the value of "likes_cats" from false to true and execute generate_matches() and reject_matches() 
--to update matching list and rejection list
update public.user_details set likes_cats = 'true' where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should not return record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 4 records and no record should be there related to 'Tracy'.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 2: Modifying the value of "likes_cats" from true to false and execute generate_matches() and reject_matches() 
--to update matching list and rejection list
update public.user_details set likes_cats = 'false' where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return no record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 5 records.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


/*******************************************************************************************************************************/
----------------------------------------------------5th scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/







--#######################################################################################################################################################








/*******************************************************************************************************************************/
----------------------------------------------------6th scenario : start----------------------------------------------------------  
/*******************************************************************************************************************************/

--Testing data by changing criteria value (religion) of a record which exists in matching list and pushing it into rejected list
--and again modifying the value of religion to bring the same record back to matching list from rejected list 

--checking matching data for 'Maria'
select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 5 records.
*/ 

--step 1: Modifying the value of "religion" from Christian to Islam and execute generate_matches() and reject_matches() 
--to update matching list and rejection list
update public.user_details set religion = 'Islam' where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should not return record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 4 records and no record should be there related to 'Tracy'.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 2: Modifying the value of "religion" from Islam to Christian and execute generate_matches() and reject_matches() 
--to update matching list and rejection list
update public.user_details set religion = 'Christian' where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return no record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 5 records.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*******************************************************************************************************************************/
----------------------------------------------------6th scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/







--#######################################################################################################################################################







/*******************************************************************************************************************************/
----------------------------------------------------7th scenario : start----------------------------------------------------------  
/*******************************************************************************************************************************/

--Test script to check the error message related to invalid username

--step 1: trying to get details of person abcde, which does not exist in the database
select * from public.get_matches('abcde');
/*
expected result :-
===================
The above query execution will throw an error - 

ERROR:  Error : User abcde does not exist
CONTEXT:  PL/pgSQL function get_matches(character varying) line 19 at RAISE
SQL state: P0001

*/

/*******************************************************************************************************************************/
----------------------------------------------------7th scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/







--#######################################################################################################################################################







/*******************************************************************************************************************************/
----------------------------------------------------8th scenario : start----------------------------------------------------------  
/*******************************************************************************************************************************/

--Testing data by changing criteria value (pokemon_catch_rate) of a record which exists in matching list and pushing it into rejected list
--and again modifying the value of pokemon_catch_rate to bring the same record back to matching list from rejected list 

--checking matching data for 'Maria'
select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 5 records.
*/ 

--step 1: Modifying the value of "pokemon_catch_rate" from .87 to .37 and execute generate_matches() and reject_matches() 
--to update matching list and rejection list
update public.user_details set pokemon_catch_rate = .37 where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should not return record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 4 records and no record should be there related to 'Tracy'.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 2: Modifying the value of "pokemon_catch_rate" from .37 to .87 and execute generate_matches() and reject_matches() 
--to update matching list and rejection list
update public.user_details set pokemon_catch_rate = .87 where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return no record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 5 records.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*******************************************************************************************************************************/
----------------------------------------------------8th scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/







--#######################################################################################################################################################







/*******************************************************************************************************************************/
----------------------------------------------------9th scenario : start----------------------------------------------------------  
/*******************************************************************************************************************************/

--Testing data by changing criteria values (likes_cats,religion) of a record which exists in rejected list and bringing into matching list

--step 1: execute view to check matching data for testing
select * from public.vw_generate_matches where match_result = 'Reject' and candidate_id = 5;

--step 2: update records for Caroline to match Caroline with Maria

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Caroline' and Id = 1)
and current_flag = 1;
/*
expected result :-
===================
The above query should not return any record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Caroline' and Id = 1)
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

--updating record in main table
--Previous: likes_cats = 'true', religion = 'Atheist'
update public.user_details set religion = 'Christian',likes_cats = 'false' where display_name = 'Caroline' and Id = 1;

--Caling the stored procedures
select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Caroline' and Id = 1)
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Caroline' and Id = 1)
and current_flag = 1;
/*
expected result :-
===================
The above query should not return any record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 6 records.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Caroline' and Id = 1);
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Caroline' and Id = 1);
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


/*******************************************************************************************************************************/
----------------------------------------------------9th scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/







--#######################################################################################################################################################







/*******************************************************************************************************************************/
----------------------------------------------------10th scenario : start----------------------------------------------------------  
/*******************************************************************************************************************************/

--Testing data by changing criteria values (religion,age) of a record which exists in matching list and pushing it into rejected list
--and again modifying the values of (religion,age) to bring the same record back to matching list from rejected list 

--checking matching data for 'Maria'
select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return 5 records.
*/ 

--step 1: Modifying the value of "religion" from Christian to Islam and age from 39 to 49 and execute generate_matches() and reject_matches() 
--to update matching list and rejection list
update public.user_details set religion = 'Islam',age = 49 where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
=================== 
The above query should not return record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should not return any record related to 'Tracy'.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--step 2: Modifying the value of "religion" from Islam to Christian and age from 49 to 39 and execute generate_matches() and reject_matches() 
--to update matching list and rejection list
update public.user_details set religion = 'Christian',age = 39 where display_name = 'Tracy';

select public.generate_matches(20000);
select public.reject_matches();

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return 1 record.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy')
and current_flag = 1;
/*
expected result :-
===================
The above query should return no record.
*/

select * from public.get_matches('Maria');
/*
expected result :-
===================
The above query should return record related to 'Tracy'.
*/ 

select * from public.user_matching_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 1.
*/

select * from public.user_rejection_details 
where user_id = (select Id from public.user_details where display_name = 'Maria')
and user_matching_id = (select Id from public.user_details where display_name = 'Tracy');
/*
expected result :-
===================
The above query should return 1 record with current_flag = 0.
*/

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*******************************************************************************************************************************/
----------------------------------------------------10th scenario : end----------------------------------------------------------  
/*******************************************************************************************************************************/







--#######################################################################################################################################################