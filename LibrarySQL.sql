use shrep

GO
CREATE SCHEMA library2o24;
GO

CREATE USER crainj; --
GRANT SELECT on schema::library2024 to crainj;

CREATE TABLE library2o24.publisher (
[name] VARCHAR(500),
city VARCHAR(500),
[address] VARCHAR(500),
CONSTRAINT publisher_pk PRIMARY KEY ([name])
);

CREATE TABLE library2o24.publication (
ISBN VARCHAR(500),
publisher_name VARCHAR(500) NOT NULL,
title VARCHAR(500),
pub_year VARCHAR(500),
edition VARCHAR(500),
genre VARCHAR(500),
card_catalog_num VARCHAR(500),
CONSTRAINT publication_pk PRIMARY KEY(ISBN),
CONSTRAINT publication_fk FOREIGN KEY (publisher_name) REFERENCES library2o24.publisher([name])
);

CREATE TABLE library2o24.author (
name VARCHAR(500),
CONSTRAINT author_pk PRIMARY KEY (name)
);

CREATE TABLE library2o24.written_by (
ISBN VARCHAR(500),
name VARCHAR(500),
CONSTRAINT written_by_pk PRIMARY KEY (ISBN, name),
CONSTRAINT written_by_fk1 FOREIGN KEY (ISBN) REFERENCES library2o24.publication(ISBN),
CONSTRAINT written_by_fk2 FOREIGN KEY (name) REFERENCES library2o24.author(name)
);

CREATE TABLE library2o24.branch (
branch_id INT NOT NULL,
name VARCHAR(500),
address VARCHAR(500),
CONSTRAINT branch_pk PRIMARY KEY (branch_id)
);

CREATE TABLE library2o24.borrower (
borrower_id INT,
branch_id INT NOT NULL,
first_name VARCHAR(500),
last_name VARCHAR(500),
address VARCHAR(500),
phone_num VARCHAR(500),
account_balance VARCHAR(500),
CONSTRAINT borrower_pk PRIMARY KEY (borrower_id),
CONSTRAINT borrower_home_branch_fk FOREIGN KEY (branch_id) REFERENCES library2o24.branch(branch_id)
);

CREATE TABLE library2o24.copy (
copy_num INT,
ISBN VARCHAR(500),
branch_id INT NOT NULL,
replace_cost_cents VARCHAR(500),
is_lost BIT DEFAULT 0,
replacement_cost_cents INT,
CONSTRAINT copy_pk PRIMARY KEY (copy_num, ISBN),
CONSTRAINT copy_fk_1 FOREIGN KEY(ISBN) REFERENCES library2o24.publication(ISBN),
CONSTRAINT copy_fk_2 FOREIGN KEY(branch_id) REFERENCES library2o24.branch(branch_id)
);

CREATE TABLE library2o24.reserves (
ISBN VARCHAR(500),
borrower_id INT,
datetime_reserved DATE,
CONSTRAINT reserves_pk PRIMARY KEY (ISBN, borrower_id),
CONSTRAINT reserves_fk_1 FOREIGN KEY (ISBN) REFERENCES library2o24.publication(ISBN),
CONSTRAINT reserves_fk_2 FOREIGN KEY (borrower_id) REFERENCES library2o24.borrower(borrower_id)
);

CREATE TABLE library2o24.loaned_to (
copy_num INT,
ISBN VARCHAR(500),
borrower_id INT,
borrow_date DATE,
due_date DATE,
return_date DATE,
CONSTRAINT loaned_to_pk PRIMARY KEY (copy_num, ISBN, borrower_id, borrow_date),
CONSTRAINT loaned_to_fk FOREIGN KEY (copy_num, ISBN) REFERENCES library2o24.copy(copy_num, ISBN),
CONSTRAINT loaned_to_fk_2 FOREIGN KEY (borrower_id) REFERENCES library2o24.borrower(borrower_id)
);

GO

-- Insert data into the tables

INSERT INTO library2o24.author (name)
VALUES ('dj');

INSERT INTO library2o24.branch (branch_id, name, address)
VALUES ('2','Branch1', 'road1');

INSERT INTO library2o24.publisher ([name], city, [address])
VALUES ('pj', 'hicksville', '1 street');

INSERT INTO library2o24.publication (ISBN, publisher_name, title, pub_year, edition, genre, card_catalog_num)
VALUES ('999999', 'pj', 'sql', '1999', '1st edition', 'comedy', '1');

INSERT INTO library2o24.written_by (ISBN, name)
VALUES ('999999','dj');

INSERT INTO library2o24.borrower (borrower_id, branch_id, first_name, last_name, address, phone_num, account_balance)
VALUES ('4','4','pj','jp','1place','123321','shr');

INSERT INTO library2o24.copy (copy_num, ISBN, branch_id, replace_cost_cents, is_lost)
VALUES ('6', '999999', '3', '2', '0');

INSERT INTO library2o24.reserves (ISBN, borrower_id, datetime_reserved)
VALUES ('999999', '4', '1111-01-01');

INSERT INTO library2o24.loaned_to (copy_num, ISBN, borrower_id, borrow_date, due_date, return_date)
VALUES ('6', '999999', '4', '2024-04-19', '2025-09-16', '2024-05-25');

GO

--adding flat_library to tables
INSERT INTO library2o24.publisher
([name], city, [address])
SELECT DISTINCT publisher, publisher_city, publisher_address
FROM library2o24.flat_library

INSERT INTO library2o24.publication
(ISBN, publisher_name, title, pub_year, edition, genre, card_catalog_num)
SELECT DISTINCT ISBN, publisher, title, publication_year, edition, NULL, card_catalog_number
FROM library2o24.flat_library;

INSERT INTO library2o24.author
([name])
SELECT DISTINCT author
FROM library2o24.flat_library;

INSERT INTO library2o24.written_by
(ISBN, name)
SELECT DISTINCT ISBN, publisher
FROM library2o24.flat_library;

INSERT INTO library2o24.branch (branch_id, name, address)
SELECT DISTINCT branch_located_at, location_branch_name, location_branch_address
FROM library2o24.flat_library
WHERE branch_located_at NOT IN (SELECT branch_id FROM library2o24.branch);

INSERT INTO library2o24.borrower (borrower_id, branch_id, first_name, last_name, address, phone_num, account_balance)
SELECT DISTINCT fl.borrower_id, b.branch_id, fl.first_name, fl.last_name, fl.borrower_address, null, null
FROM library2o24.flat_library fl
INNER JOIN library2o24.branch b ON fl.borrower_home_branch_id = b.branch_id;

INSERT INTO library2o24.copy (copy_num, ISBN, branch_id, replace_cost_cents, is_lost)
SELECT DISTINCT copy_number, ISBN, branch_located_at, replacement_cost_cents, null
FROM library2o24.flat_library;

INSERT INTO library2o24.reserves (ISBN, borrower_id, datetime_reserved)
SELECT DISTINCT ISBN, borrower_id, null
FROM library2o24.flat_library;

INSERT INTO library2o24.loaned_to(copy_num, ISBN, borrower_id, borrow_date, due_date, return_date)
SELECT DISTINCT copy_number, ISBN, borrower_id, borrow_date, due_date, return_date
FROM library2o24.flat_library;

-- creating view
CREATE VIEW library2o24.all_loans AS
SELECT
lt.copy_num,
lt.ISBN,
lt.borrower_id,
lt.borrow_date,
lt.due_date,
lt.return_date,
c.replace_cost_cents,
c.is_lost,
b.first_name AS borrower_first_name,
b.last_name AS borrower_last_name,
b.address AS borrower_address,
b.phone_num AS borrower_phone_num,
p.title AS publication_title,
p.genre AS publication_genre,
pb.name AS publisher_name
FROM
library2o24.loaned_to lt
INNER JOIN
library2o24.copy c ON lt.copy_num = c.copy_num AND lt.ISBN = c.ISBN
INNER JOIN
library2o24.borrower b ON lt.borrower_id = b.borrower_id
INNER JOIN
library2o24.publication p ON lt.ISBN = p.ISBN
INNER JOIN
library2o24.publisher pb ON p.publisher_name = pb.name;

--print flat_library and view
SELECT * FROM library2o24.flat_library
SELECT * FROM library2o24.all_loans

--print tables
SELECT * FROM shrep.library2o24.publisher
SELECT * FROM shrep.library2o24.publication
SELECT * FROM shrep.library2o24.author
SELECT * FROM shrep.library2o24.borrower
SELECT * FROM shrep.library2o24.copy
SELECT * FROM shrep.library2o24.reserves
SELECT * FROM shrep.library2o24.loaned_to
SELECT * FROM shrep.library2o24.branch
SELECT * FROM shrep.library2o24.written_by

SELECT * FROM library2o24.publisher
SELECT * FROM library2o24.publication
SELECT * FROM library2o24.author
SELECT * FROM library2o24.borrower
SELECT * FROM library2o24.copy
SELECT * FROM library2o24.reserves
SELECT * FROM library2o24.loaned_to

--deletes
DROP VIEW IF EXISTS library2o24.all_loans;
--DROP TABLE library2o24.publisher;
--DROP TABLE library2o24.publication;
--DROP TABLE library2o24.copy;
--DROP TABLE library2o24.author;
--DROP TABLE library2o24.branch;
--DROP TABLE library2o24.borrower;
--DROP TABLE library2o24.written_by;
--DROP TABLE library2o24.reserves;
--DROP TABLE library2o24.loaned_to;

GRANT SELECT ON library2o24.all_loans TO crainj;
