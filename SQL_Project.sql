-- ==================================== --
-- MSc in DSAIS 
-- 2024-2025
-- SQL Project
-- ==================================== --

-- ==================================== --
-- PART ONE: Evaluate data imperfection
-- ==================================== --

-- Exercice 1: Dealing with NULL and N/A
-- We want to be able to study the evolution of the duration of the films through the years. 
-- But first we need to make sure there are no missing values.
-- Focus on columns : movie_title, duration, title_year
-- 1) Write a query to know if there are missing values in those columns (be careful about how they are represented!)
-- Qualify them
-- 2) How many records are concerned? Make sure to have your result as a proportion of the total nb of records.
-- 3) Select all the data, excluding the rows with missing values.
SET SQL_SAFE_UPDATES = 0;

SHOW DATABASES;
USE movies;
SELECT * FROM metadata;

SELECT movie_title, duration, title_year
FROM metadata
;
-- select relevant columns for exercise 1)

-- Checking IS NULL
SELECT 
    COUNT(*) AS total_records,
    SUM(movie_title IS NULL),
    SUM(duration IS NULL),
    SUM(title_year IS NULL)
FROM 
    metadata
    ;

-- checking total missing values for all three columns on IS NULL, '', or 0 
SELECT 
    COUNT(*) AS total_records,
    SUM(movie_title IS NULL OR movie_title = '') AS missing_movie_title,
    SUM(duration IS NULL OR duration = 0 OR duration = '') AS missing_duration,
    SUM(title_year IS NULL OR title_year = 0 OR title_year = '') AS missing_title_year
FROM 
    metadata
    ;
    
-- Checking discrepancy in title year
SELECT movie_title, duration, title_year
    FROM metadata
    WHERE title_year = 0
    ;

-- Qualifying missing values not labeled as IS NULL
UPDATE metadata
SET title_year = NULL
WHERE title_year IN ('PG-13', 'USA', 'TV-14', 'R')
;
-- Checking if it worked
SELECT movie_title, duration, title_year
    FROM metadata
    WHERE title_year = 0
    ;

-- 2) How many records are concerned? Make sure to have your result as a proportion of the total nb of records.
SELECT 
    COUNT(*) AS total_records,
    SUM(movie_title IS NULL) / count(*),
    SUM(duration IS NULL)  / count(*),
    SUM(title_year IS NULL)  / count(*)
FROM 
    metadata
    ;
-- 3) Select all the data, excluding the rows with missing values.
SELECT movie_title, duration, title_year
FROM metadata
WHERE title_year IS NOT NULL
;

-- -----------
-- Exercice 2: Dealing with Duplicate Records - Removing them
-- (On the table metadata from the movies database).
-- We still want to be able to study the evolution of the duration of the films through the years. But first we need to make sure there are no duplicates.
-- Focus on the same columns: movie_title, duration, title_year,
-- Plus we add director_name to know wether they are real duplicates or movies with the same name
 
-- 1) Write a query to know whether there is duplicates in those columns.

SELECT 
    movie_title, duration, title_year, director_name, COUNT(*) AS occurrences
FROM 
    metadata
GROUP BY 
    movie_title, duration, title_year, director_name
HAVING 
    COUNT(*) > 1
ORDER BY 
    occurrences DESC;

-- 2) Select the duplicates and try to understand why we have duplicates.


SELECT *
FROM metadata
WHERE movie_title = 'King Kong ';
-- By examining this query we find out that the reason for duplicates is because the num_voted_users and cast_total_facebook_likes differs in each row


-- 3) How many records are concerned? Make sure to have your result as a proportion of the total nb of records.

SELECT COUNT(*) 
FROM (
    SELECT movie_title, duration, title_year, director_name
    FROM metadata
    GROUP BY movie_title, duration, title_year, director_name
    HAVING COUNT(*) > 1
) AS duplicates;

SELECT 
    (SELECT COUNT(*) 
     FROM (
         SELECT movie_title, duration, title_year, director_name
         FROM metadata
         GROUP BY movie_title, duration, title_year, director_name
         HAVING COUNT(*) > 1
     ) AS duplicates) / CAST(COUNT(*) AS FLOAT) AS duplicate_proportion
FROM metadata;

-- We found out that there is a 2% proportion of duplicates in the whole dataset 

-- 4) Select all the data, excluding the rows with missing values and the duplicates.

SELECT DISTINCT movie_title, duration, title_year, director_name
FROM metadata 
WHERE title_year IS NOT NULL 
ORDER BY movie_title 
;
-- This query focuses only in movie title duration; title year and director name, it shows all rows where we dont have missing values and the distinct values, this is a simple query to obtain the data where we are only excluding the null title year and using SELECT DISTINCT to exclude the duplicates.
-- The following code would get us a query where we check for missing values not only in title year but also movie title and duration. For the duplicates; in this case the code will use a subauery to exclude rows with duplicates. 

SELECT *
FROM metadata
WHERE 
    movie_title IS NOT NULL 
    AND duration IS NOT NULL 
    AND title_year IS NOT NULL 
    AND director_name IS NOT NULL
    AND (movie_title, duration, title_year, director_name) NOT IN (
        SELECT movie_title, duration, title_year, director_name
        FROM metadata
        GROUP BY movie_title, duration, title_year, director_name
        HAVING COUNT(*) > 1
    ); 

SELECT * FROM metadata;

-- -----------
-- Exercise 3 
-- 1) Explore carefully the table, do you notice anything?
-- Try to identify a maximum of issues on metadata design :
-- You can write down here your comments as well as your queries that 
-- helped you to identify those issues

SELECT * FROM metadata;
-- We display the whole table to find issues
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'metadata'
  AND COLUMN_NAME IN ('num_critic_for_reviews','duration','director_facebook_likes','actor_3_facebook_likes','actor_1_facebook_likes','gross','num_voted_users','cast_total_facebook_likes','facenumber_in_poster','num_user_for_reviews','budget','title_year','actor_2_facebook_likes','imdb_score','aspect_ratio','movie_facebook_likes');
-- We check the type associated with the columns where we observed irregular content so we can see if there is a mistake  

-- Column structure not nice at all, should completely reshuffle so that everything from actor 1 is together, everyhting from actor 2 etc.
-- Color column has only two values; Boolean, column title is missleading
-- Genre column has multiple values and seperated with |, same with plot keywords column
-- Some movies missing facebook likes
-- By misusage of the commas some values are in the wrong column 
-- Therefore, some of numbers columns are classified as text and are separated by commas when mentioning hundreds or thousands
-- Some movie titles start with " and have spaces in the end
-- actor_3_facebook_likes also contains empty rows 

-- 2) Try to select the problematic rows and to understand the problem.
SELECT *FROM metadata WHERE actor_3_facebook_likes NOT REGEXP '[0-9]';
-- We verify if in actor_3_facebook_likes contain non numeric values 
UPDATE metadata
SET actor_3_facebook_likes = NULL
WHERE actor_3_facebook_likes = '';
-- We replace the missing values with NULL so we dont have rows that contain empty values 
SELECT *
FROM metadata
WHERE actor_3_facebook_likes NOT REGEXP '[0-9]'
  AND actor_3_facebook_likes IS NOT NULL;
-- Check the rows that contain valid actor_3_facebook_likes to make sure there is no need to make additional corrections 

SELECT *
FROM metadata
WHERE actor_3_name REGEXP '[0-9]';
-- With above code we see the rows, where the values have shifted across. The reason for this shift is that the name contains a comma or there is a typing mistake.
-- We can actually now identify that the problem with these columns is that the movie_title has continued in the num_voted_users column

-- 3) How many records are concerned? Make sure to have your result as a proportion of the total nb of records.
SELECT 
    (SELECT COUNT(*) 
     FROM metadata
     WHERE actor_3_name REGEXP '[0-9]'
    ) / CAST(COUNT(*) AS FLOAT) AS digit_proportion
FROM metadata;
-- The code above provides us the ratio of affected rows; it is 1.35%

-- 4) Select all the data, excluding the rows with missing values, duplicates AND corrupted data.

SELECT *
FROM metadata
WHERE 
    movie_title IS NOT NULL 
    AND duration IS NOT NULL 
    AND title_year IS NOT NULL 
    AND director_name IS NOT NULL
    AND actor_3_name IS NOT NULL
    AND actor_3_name NOT REGEXP '[0-9]'
    AND (movie_title, duration, title_year, director_name) NOT IN (
        SELECT movie_title, duration, title_year, director_name
        FROM metadata
        GROUP BY movie_title, duration, title_year, director_name
        HAVING COUNT(*) > 1
    );



-- ==================================== --
-- PART TWO: Make ambitious table junction
-- ==================================== --
-- The database “movies” contains two kind of ratings. 
-- One “rating” is in the table “ratings” and is link to a “movieId”. 
-- The other, “imdb_score”, is in the “metadata” table. 
-- What we want here is to make an ambitious junction between the two table and get, per movie, the two kind of ratings available in this database.
-- Why ambitious? 
-- Because as you can see there is no common key or even common attribute between the two tables. 
-- In fact, there is no perfectly identic attributes but there is one eventually common value : the movie title.
-- Here, the issue here is how formate/clean your table’s data so you could make a proper join.
-- ====== --
-- Step 1:
-- What is the difference between the two attributes metadata.movie_title and movies.title ?
-- Only comment here
select movie_title from metadata
order by movie_title;
select title from movies
order by title;
 
-- By looking at both attributes, it's clear to see that the formatting of the values is different: 
-- in the movies table, the movie title and the year are wirtten in the same column, 
-- in the metadata table, the two features are separates into two different columns
-- Additionally, the two tables have different titles, with movies having  4915 titles (4788 of which unique), and metadata with 9125 (9123 unique) titles.


-- ====== --
-- Step 2:
-- How to cut out some unwanted pieces of a string ? 
-- Use the function SUBSTR() but you will also need another function : CHAR_LENGTH().
-- From the movies table, 
-- Try to get a query returning the movie.title, considering only the correct title of each movie.

SELECT title, SUBSTR(title, 1, CHAR_LENGTH(title) - 6) AS movie_title 
FROM movies
;
-- We used CHAR LENGHT with - 6 to get the total lenght of the string substracting the last - chraracters

-- And then also include the aggregation of the average rating for each movie
-- joining the ratings table

SELECT movies.title, SUBSTR(movies.title, 1, CHAR_LENGTH(movies.title) - 6) AS movie_title, AVG(ratings.rating) AS average_rating 
FROM movies
JOIN ratings ON movies.movieId = ratings.movieId
GROUP BY movies.title
;

-- Join both tables aggregating the rating 

-- ====== --
-- Step 3:
-- Now that we have a good request for cleaned and aggregated version of movies/ratings, 
-- you need to also have a clean request from metadata.
-- Make a query returning aggregated metadata.imdb_score for each metadata.movie_title.
-- excluding the corrupted rows 

SELECT movie_title, avg(imdb_score) AS average_imbd_score 
FROM metadata
WHERE imdb_score IS NOT NULL
AND (imdb_score >= 0 AND imdb_score <= 10)
GROUP BY movie_title
;
-- This query will return the average score IMBD score for each unique movie title

-- ====== --
-- Step 4:
-- It is time to make a JOIN! Try to make a request merging the result of Step 2 and Step 3. 
-- You need to use your previous as two subqueries and join on the movie title.
-- What is happening ? What is the result ? This request can take time to return.

SELECT movies_ratings.title, movies_ratings.movie_title, movies_ratings.average_rating, metadata_avg.average_imbd_score
FROM 
    (SELECT movies.title, SUBSTR(movies.title, 1, CHAR_LENGTH(movies.title) - 6) AS movie_title, AVG(ratings.rating) AS average_rating 
    FROM movies 
    JOIN ratings ON movies.movieId = ratings.movieId
    GROUP BY movies.title
    ) AS movies_ratings
JOIN 
    (SELECT movie_title, avg(imdb_score) AS average_imbd_score 
    FROM metadata
    WHERE imdb_score IS NOT NULL 
    AND (imdb_score >= 0 AND imdb_score <= 10)
    GROUP BY movie_title
    ) AS metadata_avg
ON movies_ratings.movie_title = metadata_avg.movie_title;

-- This query joins the two tables, movies ratings and meta data avg to compare the average ratings of movies in the two different datasets, movies (joined with ratings) and metadata.

-- ====== --
-- Step 5:
-- There is a possibility that your previous query doesn't work for apparently no reasons, 
-- despite of the join condition being respected on some rows 
-- (check by yourself on a specific film of your choice by adding a simple WHERE condition).
-- Try to find out what could go wrong 
-- And try to query a workable join
-- Tip: Think about spaces or blanks 

-- finding the names of the missing movieId's
SELECT movies.movieId, movies.title
FROM movies
LEFT JOIN ratings ON movies.movieId = ratings.movieId
WHERE ratings.movieId IS NULL;

-- this shows that the merge was done on the smaller table with the missing movieId, so when we search for a movie that exists in one table, it does not exist in our merged table.
SELECT movies_ratings.movie_title, 
       movies_ratings.average_rating, 
       metadata_avg.average_imbd_score
FROM 
    (SELECT SUBSTR(movies.title, 1, CHAR_LENGTH(movies.title) - 6) AS movie_title, 
            AVG(ratings.rating) AS average_rating 
     FROM movies 
     JOIN ratings ON movies.movieId = ratings.movieId
     GROUP BY movies.title
    ) AS movies_ratings
JOIN 
    (SELECT movie_title, 
            AVG(imdb_score) AS average_imbd_score 
     FROM metadata
     WHERE imdb_score IS NOT NULL 
       AND imdb_score BETWEEN 0 AND 10
     GROUP BY movie_title
    ) AS metadata_avg
ON movies_ratings.movie_title = metadata_avg.movie_title
WHERE movies_ratings.movie_title = 'Fire';

-- Query to list distinct movie IDs from both tables to check for matches and mismatches
SELECT m.movieId AS MovieID_in_Movies, r.movieId AS MovieID_in_Ratings
FROM (SELECT DISTINCT movieId FROM movies) AS m
LEFT JOIN (SELECT DISTINCT movieId FROM ratings) AS r
ON m.movieId = r.movieId

UNION 

SELECT m.movieId AS MovieID_in_Movies, r.movieId AS MovieID_in_Ratings
FROM (SELECT DISTINCT movieId FROM ratings) AS r
LEFT JOIN (SELECT DISTINCT movieId FROM movies) AS m
ON r.movieId = m.movieId
ORDER BY MovieID_in_Movies ASC, MovieID_in_Ratings ASC;

-- Can confirm that movieId in ratings and mvoies have different distinct values. Movies contains more distinct values than ratings. 
-- We joined on rating, therefore there are no gaps or null values when we merged it with metadata.
-- to check this, we created a union. In the union we can identify a number of missing movieId from the ratings table that are present in the movie table (ex: 4763, 4763, 4763). When these movieId's are checed in the following merged table, they do not exist, this why our merge is working. 


SELECT  movies_ratings.movie_title, movies_ratings.average_rating, metadata_avg.average_imbd_score
FROM 
    (SELECT SUBSTR(movies.title, 1, CHAR_LENGTH(movies.title) - 6) AS movie_title, AVG(ratings.rating) AS average_rating 
    FROM movies 
    JOIN ratings ON movies.movieId = ratings.movieId
    GROUP BY movies.title
    ) AS movies_ratings
JOIN 
    (SELECT movie_title, avg(imdb_score) AS average_imbd_score 
    FROM metadata
    WHERE imdb_score IS NOT NULL 
    AND (imdb_score >= 0 AND imdb_score <= 10)
    GROUP BY movie_title
    ) AS metadata_avg
ON movies_ratings.movie_title = metadata_avg.movie_title;



-- For final version of the output, 
-- Also include the count of ratings used to compute the average.

-- adding in count of each rating 
SELECT movies_ratings.movie_title, 
	   movies_ratings.average_rating, 
	   movies_ratings.rating_count,
	   metadata_avg.average_imdb_score
FROM 
	(SELECT SUBSTR(movies.title, 1, CHAR_LENGTH(movies.title) - 6) AS movie_title, 
			AVG(ratings.rating) AS average_rating, 
			COUNT(ratings.rating) AS rating_count
	 FROM movies 
	 JOIN ratings ON movies.movieId = ratings.movieId
	 GROUP BY movies.title
	) AS movies_ratings
JOIN 
	(SELECT movie_title, AVG(imdb_score) AS average_imdb_score 
	 FROM metadata
	 WHERE imdb_score IS NOT NULL 
	   AND (imdb_score >= 0 AND imdb_score <= 10)
	 GROUP BY movie_title
	) AS metadata_avg
ON movies_ratings.movie_title = metadata_avg.movie_title
;
   
   
-- ------------------
-- Well done ! 
-- Congratulations !
-- ------------------
