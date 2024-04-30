-- Active: 1713131343248@@127.0.0.1@3306@WorkVisaLotteryProgramDB
DROP DATABASE IF EXISTS WorkVisaLotteryProgramDB;

CREATE DATABASE WorkVisaLotteryProgramDB DEFAULT CHARACTER SET = 'utf8mb4';

USE WorkVisaLotteryProgramDB;
DROP TABLE IF EXISTS Result;
DROP TABLE IF EXISTS Employer;
DROP TABLE IF EXISTS IndustryCode;

-- Create North American Industry Classification System (NAICS) Code table
CREATE TABLE IndustryCode (
    industry_code VARCHAR(5) PRIMARY KEY,
    industry_description VARCHAR(255)
);

-- Create Employer table
CREATE TABLE Employer (
    employer_id INT PRIMARY KEY AUTO_INCREMENT,
    employer_name VARCHAR(255),
    employer_tax_id VARCHAR(4),
    employer_city VARCHAR(100),
    employer_state VARCHAR(2),
    employer_zip_code VARCHAR(5),
    employer_industry_code VARCHAR(5),
    FOREIGN KEY (employer_industry_code) REFERENCES IndustryCode(industry_code)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    UNIQUE(employer_name, employer_tax_id, employer_city, employer_state, employer_zip_code)
);

-- Create Result table
CREATE TABLE Result (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fiscal_year INT NOT NULL,
    employer_id INT,
    registrations INT NOT NULL,
    approval_status BOOLEAN NOT NULL,
    initial_round BOOLEAN NOT NULL,
    FOREIGN KEY (employer_id) REFERENCES Employer(employer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);