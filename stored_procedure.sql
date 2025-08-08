-- 1. SP "Factorial". SP calculates the factorial of a given number. (5! = 1 * 2 * 3 * 4 * 5 = 120 ) 
-- (the factorial of a negative number does not exist).


CREATE PROCEDURE LazyStudents
    @studentsCount INT OUTPUT
AS
BEGIN

    SELECT s.StudentId, s.FirstName, s.LastName
    FROM dbo.Students s
    LEFT JOIN dbo.BookLoans bl ON s.StudentId = bl.StudentId
    WHERE bl.BookId IS NULL;
    

    SELECT @studentsCount = COUNT(DISTINCT s.StudentId)
    FROM dbo.Students s
    LEFT JOIN dbo.BookLoans bl ON s.StudentId = bl.StudentId
    WHERE bl.BookId IS NULL;
END;


--------------------------------------------------------------------------------------------------------------

-- 2. SP "Lazy Students." SP displays students who never took books in the library and through the output parameter returns the number of these students.

CREATE PROCEDURE LazyStudents2
    @LazyStudent2Count INT OUTPUT
AS
BEGIN

    SELECT s.StudentId, s.FirstName, s.LastName
    FROM dbo.Students s
    LEFT JOIN dbo.BookLoans bl ON s.StudentId = bl.StudentId
    WHERE bl.BookId IS NULL;  

    SELECT @LazyStudent2Count = COUNT(*) 
    FROM dbo.Students s
    LEFT JOIN dbo.BookLoans bl ON s.StudentId = bl.StudentId
    WHERE bl.BookId IS NULL; 
END;


--------------------------------------------------------------------------------------------------------------


-- 3. SP "Books on the criteria." SP displays a list of books that matching criterion: 
-- the author's name, surname, subject, category. In addition, the list should be sorted by the column number specified in the 5th parameter, 
-- in the direction indicated in parameter 
-- 6. Columns: 1) book identifier, 2) book title, 3) surname and name of the author, 4) topic, 5) category.


CREATE PROCEDURE BooksOnTheCriteria
    @AuthorName NVARCHAR(100) = NULL,
    @AuthorSurname NVARCHAR(100) = NULL,
    @Subject NVARCHAR(100) = NULL,
    @Category NVARCHAR(100) = NULL,
    @SortColumn INT = 1,  
    @SortDirection NVARCHAR(4) = 'ASC' 
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = 'SELECT b.BookId, b.Title, a.FirstName + '' '' + a.LastName AS Author, b.Subject, b.Category
                FROM dbo.Books b
                JOIN dbo.Authors a ON b.AuthorId = a.AuthorId
                WHERE 1=1';

    IF @AuthorName IS NOT NULL
        SET @SQL = @SQL + ' AND a.FirstName LIKE ''%' + @AuthorName + '%''';

    IF @AuthorSurname IS NOT NULL
        SET @SQL = @SQL + ' AND a.LastName LIKE ''%' + @AuthorSurname + '%''';

    IF @Subject IS NOT NULL
        SET @SQL = @SQL + ' AND b.Subject LIKE ''%' + @Subject + '%''';

    IF @Category IS NOT NULL
        SET @SQL = @SQL + ' AND b.Category LIKE ''%' + @Category + '%''';

    IF @SortColumn = 1
        SET @SQL = @SQL + ' ORDER BY b.BookId ' + @SortDirection;
    ELSE IF @SortColumn = 2
        SET @SQL = @SQL + ' ORDER BY b.Title ' + @SortDirection;
    ELSE IF @SortColumn = 3
        SET @SQL = @SQL + ' ORDER BY a.FirstName + '' '' + a.LastName ' + @SortDirection;
    ELSE IF @SortColumn = 4
        SET @SQL = @SQL + ' ORDER BY b.Subject ' + @SortDirection;
    ELSE IF @SortColumn = 5
        SET @SQL = @SQL + ' ORDER BY b.Category ' + @SortDirection;

    EXEC sp_executesql @SQL;
END;

--------------------------------------------------------------------------------------------------------------

-- 4. SP "Adding a student." SP adds a student and a group. 
-- If the group with this name exists, specify the Id of the group in Id_Group. 
-- If this name does not exist: first add the group and then the student. Note that the group names are stored in uppercase, 
-- but no one guarantees that the user will give the name in uppercase.


CREATE PROCEDURE AddStudent
    @StudentName NVARCHAR(100),
    @StudentSurname NVARCHAR(100),
    @GroupName NVARCHAR(100),
    @Id_Group INT OUTPUT
AS
BEGIN
    SET @GroupName = UPPER(@GroupName);

    IF EXISTS (SELECT 1 FROM dbo.Groups WHERE GroupName = @GroupName)
    BEGIN
        SELECT @Id_Group = GroupId FROM dbo.Groups WHERE GroupName = @GroupName;
        INSERT INTO dbo.Students (FirstName, LastName, Id_Group)
        VALUES (@StudentName, @StudentSurname, @Id_Group);
    END
    ELSE
    BEGIN
        INSERT INTO dbo.Groups (GroupName)
        VALUES (@GroupName);
        SET @Id_Group = SCOPE_IDENTITY();
        INSERT INTO dbo.Students (FirstName, LastName, Id_Group)
        VALUES (@StudentName, @StudentSurname, @Id_Group);
    END
END;

--------------------------------------------------------------------------------------------------------------

-- 5. SP "Purchase of popular books." SP chooses the top 5 most popular books 
--(among students and teachers simultaneously) and buys another 3 copies of every book.


--------------------------------------------------------------------------------------------------------------

-- 6. SP "Getting rid of unpopular books." SP chooses top 5 non-popular books and gives half to another educational institution.


--------------------------------------------------------------------------------------------------------------


-- 7. SP "A student takes a book." SP gets Id of a student and Id of a book. 
--Check the quantity of books in table Books (if quantity > 0). Check how many books a student has now. 
--If there are 3-4 books, then we issue a warning, and if there are already 5 books, then we do not give him a new book. 
--If a student can take this book, then add rows in table S_Cards and update column quantity in table Books.


CREATE PROCEDURE StudentTakesBook
    @StudentId INT,
    @BookId INT
AS
BEGIN
    DECLARE @BookQuantity INT;
    DECLARE @StudentBooksCount INT;

    SELECT @BookQuantity = Quantity FROM dbo.Books WHERE BookId = @BookId;

    IF @BookQuantity > 0
    BEGIN
        SELECT @StudentBooksCount = COUNT(*) FROM dbo.S_Cards WHERE StudentId = @StudentId;

        IF @StudentBooksCount >= 5
        BEGIN
            RETURN;
        END

        IF @StudentBooksCount >= 3
        BEGIN
        END

        INSERT INTO dbo.S_Cards (StudentId, BookId, IssueDate)
        VALUES (@StudentId, @BookId, GETDATE());

        UPDATE dbo.Books
        SET Quantity = @BookQuantity - 1
        WHERE BookId = @BookId;
    END
    ELSE
    BEGIN
    END
END;


--------------------------------------------------------------------------------------------------------------

-- 8. SP "Teacher takes the book."


CREATE PROCEDURE TeacherTakesBook
    @TeacherId INT,
    @BookId INT
AS
BEGIN
    DECLARE @BookQuantity INT;
    DECLARE @TeacherBooksCount INT;

    SELECT @BookQuantity = Quantity FROM dbo.Books WHERE BookId = @BookId;

    IF @BookQuantity > 0
    BEGIN
        SELECT @TeacherBooksCount = COUNT(*) FROM dbo.T_Cards WHERE TeacherId = @TeacherId;

        INSERT INTO dbo.T_Cards (TeacherId, BookId, IssueDate)
        VALUES (@TeacherId, @BookId, GETDATE());

        UPDATE dbo.Books
        SET Quantity = @BookQuantity - 1
        WHERE BookId = @BookId;
    END
END;

--------------------------------------------------------------------------------------------------------------


-- 9. SP "The student returns the book." SP receives Student's Id and Book's Id. In the table S_Cards information is entered about the return of the book. Also you need to add quantity in table Books. If the student has kept the book for more than a year, then he is fined.


CREATE PROCEDURE StudentReturnsBook
    @StudentId INT,
    @BookId INT
AS
BEGIN
    DECLARE @IssueDate DATE;
    DECLARE @BookQuantity INT;
    DECLARE @FineAmount DECIMAL(10,2);

    SELECT @IssueDate = IssueDate FROM dbo.S_Cards WHERE StudentId = @StudentId AND BookId = @BookId;

    IF DATEDIFF(YEAR, @IssueDate, GETDATE()) > 1
    BEGIN
        SET @FineAmount = 10.00; -- Example fine
        UPDATE dbo.S_Cards SET Fine = @FineAmount WHERE StudentId = @StudentId AND BookId = @BookId;
    END

    DELETE FROM dbo.S_Cards WHERE StudentId = @StudentId AND BookId = @BookId;

    SELECT @BookQuantity = Quantity FROM dbo.Books WHERE BookId = @BookId;
    UPDATE dbo.Books SET Quantity = @BookQuantity + 1 WHERE BookId = @BookId;
END;

--------------------------------------------------------------------------------------------------------------


-- 10. SP "Teacher returns book".


CREATE PROCEDURE TeacherReturnsBook
    @TeacherId INT,
    @BookId INT
AS
BEGIN
    DECLARE @IssueDate DATE;
    DECLARE @BookQuantity INT;

    SELECT @IssueDate = IssueDate FROM dbo.T_Cards WHERE TeacherId = @TeacherId AND BookId = @BookId;

    DELETE FROM dbo.T_Cards WHERE TeacherId = @TeacherId AND BookId = @BookId;

    SELECT @BookQuantity = Quantity FROM dbo.Books WHERE BookId = @BookId;
    UPDATE dbo.Books SET Quantity = @BookQuantity + 1 WHERE BookId = @BookId;
END;

