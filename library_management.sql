-- library_management.sql
-- ----------------------------------------------------
-- 1. Create database (drop if exists)
-- ----------------------------------------------------
DROP DATABASE IF EXISTS LibraryDB;
CREATE DATABASE LibraryDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE LibraryDB;

-- ----------------------------------------------------
-- 2. Tables
-- ----------------------------------------------------

-- Publishers
DROP TABLE IF EXISTS Publishers;
CREATE TABLE Publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    address VARCHAR(500),
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Authors
DROP TABLE IF EXISTS Authors;
CREATE TABLE Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    biography TEXT,
    UNIQUE (first_name, last_name)
) ENGINE=InnoDB;

-- Categories
DROP TABLE IF EXISTS Categories;
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500)
) ENGINE=InnoDB;

-- Books (logical book)
DROP TABLE IF EXISTS Books;
CREATE TABLE Books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    publisher_id INT,
    publication_year YEAR,
    pages INT,
    language VARCHAR(50),
    summary TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id)
      ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- BookAuthors (many-to-many Books <-> Authors)
DROP TABLE IF EXISTS BookAuthors;
CREATE TABLE BookAuthors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    author_order SMALLINT DEFAULT 1,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
      ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (author_id) REFERENCES Authors(author_id)
      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- BookCategories (many-to-many Books <-> Categories)
DROP TABLE IF EXISTS BookCategories;
CREATE TABLE BookCategories (
    book_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
      ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- BookCopies (physical copies)
DROP TABLE IF EXISTS BookCopies;
CREATE TABLE BookCopies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    barcode VARCHAR(50) UNIQUE,
    acquisition_date DATE,
    `condition` ENUM('New','Good','Fair','Poor') DEFAULT 'Good',
    location VARCHAR(100),
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Members (library patrons)
DROP TABLE IF EXISTS Members;
CREATE TABLE Members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(50),
    address VARCHAR(500),
    join_date DATE DEFAULT (CURRENT_DATE),
    is_active BOOLEAN DEFAULT TRUE,
    CHECK (email LIKE '%_@_%._%')
) ENGINE=InnoDB;

-- Staff
DROP TABLE IF EXISTS Staff;
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role ENUM('Admin','Librarian','Assistant') DEFAULT 'Assistant',
    email VARCHAR(255) UNIQUE,
    hired_date DATE,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- Loans (track borrowing of copies)
DROP TABLE IF EXISTS Loans;
CREATE TABLE Loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    staff_id INT,
    loan_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    return_date DATE,
    status ENUM('On Loan','Returned','Overdue','Lost') NOT NULL DEFAULT 'On Loan',
    fines_due DECIMAL(8,2) DEFAULT 0.00,
    FOREIGN KEY (copy_id) REFERENCES BookCopies(copy_id)
      ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (member_id) REFERENCES Members(member_id)
      ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id)
      ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_due_after_loan CHECK (due_date >= loan_date)
) ENGINE=InnoDB;

-- Reservations (reserve a logical book)
DROP TABLE IF EXISTS Reservations;
CREATE TABLE Reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    reserve_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    status ENUM('Active','Cancelled','Fulfilled','Expired') DEFAULT 'Active',
    expires_on DATE,
    FOREIGN KEY (member_id) REFERENCES Members(member_id)
      ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Fines (payments for loans)
DROP TABLE IF EXISTS Fines;
CREATE TABLE Fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    amount DECIMAL(8,2) NOT NULL CHECK (amount >= 0),
    assessed_date DATE DEFAULT (CURRENT_DATE),
    paid_date DATE,
    status ENUM('Unpaid','Paid','Waived') DEFAULT 'Unpaid',
    FOREIGN KEY (loan_id) REFERENCES Loans(loan_id)
      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Activity Log (optional)
DROP TABLE IF EXISTS ActivityLog;
CREATE TABLE ActivityLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_type ENUM('Member','Staff','System') NOT NULL,
    user_id INT,
    action VARCHAR(255) NOT NULL,
    details TEXT
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- 3. Indexes (improve lookup speed)
-- ----------------------------------------------------
CREATE INDEX idx_books_title ON Books(title(200));
CREATE INDEX idx_copies_book ON BookCopies(book_id);
CREATE INDEX idx_loans_member ON Loans(member_id);
CREATE INDEX idx_reservations_member ON Reservations(member_id);

-- ----------------------------------------------------
-- 4. Example triggers (optional) - keep or remove
-- ----------------------------------------------------
-- Mark copy unavailable when a new loan is inserted
DROP TRIGGER IF EXISTS trg_loans_after_insert;
DELIMITER $$
CREATE TRIGGER trg_loans_after_insert
AFTER INSERT ON Loans
FOR EACH ROW
BEGIN
    UPDATE BookCopies SET is_available = FALSE WHERE copy_id = NEW.copy_id;
END$$
DELIMITER ;

-- When a loan is updated to Returned, mark copy available
DROP TRIGGER IF EXISTS trg_loans_after_update;
DELIMITER $$
CREATE TRIGGER trg_loans_after_update
AFTER UPDATE ON Loans
FOR EACH ROW
BEGIN
    IF NEW.status = 'Returned' THEN
        UPDATE BookCopies SET is_available = TRUE WHERE copy_id = NEW.copy_id;
    ELSEIF NEW.status = 'On Loan' THEN
        UPDATE BookCopies SET is_available = FALSE WHERE copy_id = NEW.copy_id;
    END IF;
END$$
DELIMITER ;
-- End of library_management.sql
