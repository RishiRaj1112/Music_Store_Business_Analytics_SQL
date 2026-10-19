-- =====================================================================================
-- Project: Music Store Business Analytics using SQL
-- Database: MySQL 8.0+
-- File: 01_database_schema_ddl.sql
-- Description: DDL Schema creation script defining 11 normalized relational tables (3NF),
--              Primary Keys, Foreign Keys, cascade constraints, and performance indexes.
-- =====================================================================================

DROP DATABASE IF EXISTS music_store_db;
CREATE DATABASE music_store_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE music_store_db;

-- -------------------------------------------------------------------------------------
-- Table 1: EMPLOYEE (Internal organizational hierarchy)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS employee;
CREATE TABLE employee (
    employee_id INT NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    title VARCHAR(60),
    reports_to INT,
    levels VARCHAR(10),
    birthdate DATETIME,
    hire_date DATETIME,
    address VARCHAR(120),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(30),
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(100),
    CONSTRAINT pk_employee PRIMARY KEY (employee_id),
    CONSTRAINT fk_employee_reports_to FOREIGN KEY (reports_to) 
        REFERENCES employee(employee_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 2: CUSTOMER (Global customer base)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS customer;
CREATE TABLE customer (
    customer_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    company VARCHAR(120),
    address VARCHAR(120),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(30),
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(100) NOT NULL,
    support_rep_id INT,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT fk_customer_support_rep FOREIGN KEY (support_rep_id) 
        REFERENCES employee(employee_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 3: INVOICE (Transaction header table)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS invoice;
CREATE TABLE invoice (
    invoice_id INT NOT NULL,
    customer_id INT NOT NULL,
    invoice_date DATETIME NOT NULL,
    billing_address VARCHAR(120),
    billing_city VARCHAR(50),
    billing_state VARCHAR(50),
    billing_country VARCHAR(50),
    billing_postal_code VARCHAR(30),
    total DECIMAL(10, 2) NOT NULL,
    CONSTRAINT pk_invoice PRIMARY KEY (invoice_id),
    CONSTRAINT fk_invoice_customer FOREIGN KEY (customer_id) 
        REFERENCES customer(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 4: ARTIST (Music creators)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS artist;
CREATE TABLE artist (
    artist_id INT NOT NULL,
    name VARCHAR(120) NOT NULL,
    CONSTRAINT pk_artist PRIMARY KEY (artist_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 5: ALBUM (Album catalog)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS album;
CREATE TABLE album (
    album_id INT NOT NULL,
    title VARCHAR(160) NOT NULL,
    artist_id INT NOT NULL,
    CONSTRAINT pk_album PRIMARY KEY (album_id),
    CONSTRAINT fk_album_artist FOREIGN KEY (artist_id) 
        REFERENCES artist(artist_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 6: GENRE (Music categorization)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS genre;
CREATE TABLE genre (
    genre_id INT NOT NULL,
    name VARCHAR(120) NOT NULL,
    CONSTRAINT pk_genre PRIMARY KEY (genre_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 7: MEDIA_TYPE (Encoding format: AAC, MPEG, etc.)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS media_type;
CREATE TABLE media_type (
    media_type_id INT NOT NULL,
    name VARCHAR(120) NOT NULL,
    CONSTRAINT pk_media_type PRIMARY KEY (media_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 8: TRACK (Detailed catalog items - 3,500+ records)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS track;
CREATE TABLE track (
    track_id INT NOT NULL,
    name VARCHAR(220) NOT NULL,
    album_id INT,
    media_type_id INT NOT NULL,
    genre_id INT NOT NULL,
    composer VARCHAR(220),
    milliseconds INT NOT NULL,
    bytes INT,
    unit_price DECIMAL(10, 2) NOT NULL,
    CONSTRAINT pk_track PRIMARY KEY (track_id),
    CONSTRAINT fk_track_album FOREIGN KEY (album_id) 
        REFERENCES album(album_id) ON DELETE SET NULL,
    CONSTRAINT fk_track_media_type FOREIGN KEY (media_type_id) 
        REFERENCES media_type(media_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_track_genre FOREIGN KEY (genre_id) 
        REFERENCES genre(genre_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 9: INVOICE_LINE (Itemized order line items)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS invoice_line;
CREATE TABLE invoice_line (
    invoice_line_id INT NOT NULL,
    invoice_id INT NOT NULL,
    track_id INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    CONSTRAINT pk_invoice_line PRIMARY KEY (invoice_line_id),
    CONSTRAINT fk_invoice_line_invoice FOREIGN KEY (invoice_id) 
        REFERENCES invoice(invoice_id) ON DELETE CASCADE,
    CONSTRAINT fk_invoice_line_track FOREIGN KEY (track_id) 
        REFERENCES track(track_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 10: PLAYLIST (Curated music playlists)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS playlist;
CREATE TABLE playlist (
    playlist_id INT NOT NULL,
    name VARCHAR(120) NOT NULL,
    CONSTRAINT pk_playlist PRIMARY KEY (playlist_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------------------------
-- Table 11: PLAYLIST_TRACK (Junction table for many-to-many relationship)
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS playlist_track;
CREATE TABLE playlist_track (
    playlist_id INT NOT NULL,
    track_id INT NOT NULL,
    CONSTRAINT pk_playlist_track PRIMARY KEY (playlist_id, track_id),
    CONSTRAINT fk_pt_playlist FOREIGN KEY (playlist_id) 
        REFERENCES playlist(playlist_id) ON DELETE CASCADE,
    CONSTRAINT fk_pt_track FOREIGN KEY (track_id) 
        REFERENCES track(track_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================================
-- PERFORMANCE INDEXES (Optimizing multi-table JOINs and window operations)
-- =====================================================================================
CREATE INDEX idx_invoice_customer ON invoice(customer_id);
CREATE INDEX idx_invoice_date ON invoice(invoice_date);
CREATE INDEX idx_invoice_line_invoice ON invoice_line(invoice_id);
CREATE INDEX idx_invoice_line_track ON invoice_line(track_id);
CREATE INDEX idx_track_genre ON track(genre_id);
CREATE INDEX idx_track_album ON track(album_id);
CREATE INDEX idx_customer_support ON customer(support_rep_id);
