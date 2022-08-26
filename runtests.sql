-----------------------
-- Delete everything --
-----------------------

-- Use this instead of drop schema if running on the Chalmers Postgres server
-- DROP OWNED BY TDA357_XXX CASCADE;

-- Less talk please.
\set QUIET true
SET client_min_messages TO WARNING; 

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;

-- Enable log messages again.
SET client_min_messages TO NOTICE; 
\set QUIET false

-----------------------
-- Reload everything --
-----------------------

\i tables.sql;
\i views.sql;
\i inserts.sql;
\i triggers.sql;