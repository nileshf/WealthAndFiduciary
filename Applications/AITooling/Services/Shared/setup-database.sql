-- Create Databases
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SecurityDb')
BEGIN
    CREATE DATABASE SecurityDb;
END
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DataLoaderDb')
BEGIN
    CREATE DATABASE DataLoaderDb;
END
GO

-- Use SecurityDb
USE SecurityDb;
GO

-- Create Users table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        Id INT PRIMARY KEY IDENTITY(1,1),
        Username NVARCHAR(100) NOT NULL UNIQUE,
        PasswordHash NVARCHAR(255) NOT NULL,
        Role NVARCHAR(50) NOT NULL DEFAULT 'User'
    );
END
GO

-- Use DataLoaderDb
USE DataLoaderDb;
GO

-- Create DataRecords table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DataRecords')
BEGIN
    CREATE TABLE DataRecords (
        Id INT PRIMARY KEY IDENTITY(1,1),
        Name NVARCHAR(255) NOT NULL,
        Value NVARCHAR(255) NOT NULL,
        CreatedAt DATETIME2 NOT NULL
    );
END
GO

PRINT 'Database setup completed successfully!';
