-- LifeFlow Blood Bank — Full Database Schema v2
CREATE DATABASE IF NOT EXISTS blood_bank_db;
USE blood_bank_db;

-- 1. Users
CREATE TABLE IF NOT EXISTS Users (
    user_id        INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(255) NOT NULL,
    email          VARCHAR(255) UNIQUE NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    role           ENUM('Admin','Donor','Hospital') NOT NULL,
    contact_number VARCHAR(15),
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Donors
CREATE TABLE IF NOT EXISTS Donors (
    user_id            INT PRIMARY KEY,
    blood_group        VARCHAR(5) NOT NULL,
    age                INT NOT NULL,
    weight             FLOAT NOT NULL,
    last_donation_date DATE DEFAULT NULL,
    total_donations    INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- 3. Blood Inventory Summary (one row per blood group)
CREATE TABLE IF NOT EXISTS Blood_Inventory (
    blood_group  VARCHAR(5) PRIMARY KEY,
    quantity_ml  INT DEFAULT 0
);

-- 4. Blood Inventory Batches (expiry tracking)
CREATE TABLE IF NOT EXISTS Blood_Batches (
    batch_id       INT AUTO_INCREMENT PRIMARY KEY,
    blood_group    VARCHAR(5) NOT NULL,
    quantity_ml    INT NOT NULL,
    collected_date DATE NOT NULL DEFAULT '2025-01-01',  -- app always sets this explicitly
    expiry_date    DATE NOT NULL,
    batch_label    VARCHAR(50) DEFAULT NULL,
    is_expired     TINYINT(1) DEFAULT 0
);

-- 5. Blood Requests (hospitals AND donors)
CREATE TABLE IF NOT EXISTS Blood_Requests (
    request_id         INT AUTO_INCREMENT PRIMARY KEY,
    hospital_user_id   INT,
    requester_role     ENUM('Hospital','Donor') DEFAULT 'Hospital',
    blood_group        VARCHAR(5) NOT NULL,
    quantity_needed_ml INT NOT NULL,
    priority           ENUM('Normal','Urgent','Critical') DEFAULT 'Normal',
    reason             VARCHAR(255) DEFAULT NULL,
    request_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status             ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
    processed_by       INT DEFAULT NULL,
    processed_at       TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (hospital_user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- 6. Admin Activity Log
CREATE TABLE IF NOT EXISTS Admin_Activity_Log (
    log_id     INT AUTO_INCREMENT PRIMARY KEY,
    admin_id   INT NOT NULL,
    action     VARCHAR(255) NOT NULL,
    details    TEXT,
    logged_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- 7. Donor Achievements
CREATE TABLE IF NOT EXISTS Donor_Achievements (
    achievement_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    badge_key      VARCHAR(50) NOT NULL,
    earned_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_badge (user_id, badge_key),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Initialize inventory
INSERT IGNORE INTO Blood_Inventory (blood_group, quantity_ml) VALUES
('A+',0),('A-',0),('B+',0),('B-',0),('AB+',0),('AB-',0),('O+',0),('O-',0);

-- Admin accounts
INSERT IGNORE INTO Users (name, email, password_hash, role)
VALUES ('tharun',    'admin1@bloodbank.com', 'admin123', 'Admin');
INSERT IGNORE INTO Users (name, email, password_hash, role)
VALUES ('tharunesh', 'admin2@bloodbank.com', 'admin456', 'Admin');

-- ══ UPGRADE SCRIPT (run if you already have the old schema) ══
ALTER TABLE Donors ADD COLUMN IF NOT EXISTS total_donations INT DEFAULT 0;
ALTER TABLE Blood_Requests
    ADD COLUMN IF NOT EXISTS priority       ENUM('Normal','Urgent','Critical') DEFAULT 'Normal' AFTER quantity_needed_ml,
    ADD COLUMN IF NOT EXISTS reason         VARCHAR(255) DEFAULT NULL AFTER priority,
    ADD COLUMN IF NOT EXISTS requester_role ENUM('Hospital','Donor') DEFAULT 'Hospital' AFTER hospital_user_id,
    ADD COLUMN IF NOT EXISTS processed_by   INT DEFAULT NULL AFTER status,
    ADD COLUMN IF NOT EXISTS processed_at   TIMESTAMP NULL DEFAULT NULL AFTER processed_by;
