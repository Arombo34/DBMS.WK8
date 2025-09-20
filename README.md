# 📚 Library Management System - Database Project

## Overview
This project is a **MySQL-based Library Management System**.  
It is designed to manage books, authors, members, and borrowing records in a relational database.  

The project demonstrates:
- Proper use of relational database concepts
- Normalized table design
- Primary & foreign key constraints
- One-to-Many and Many-to-Many relationships

---

## 🎯 Use Case
A library needs to:
- Store details of **books** and their **authors**
- Register **members**
- Track **borrowings and returns**

---

## 📂 Database Schema
The system consists of the following tables:

1. **Authors**  
   - Stores details about book authors.

2. **Books**  
   - Stores information about books available in the library.  
   - Linked to **Authors**.

3. **Members**  
   - Stores library member details.

4. **Borrowings**  
   - Stores which member borrowed which book, and return dates.  
   - Links **Members** and **Books**.

