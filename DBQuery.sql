USE caribejobsDB;
IF OBJECT_ID('dbo.ServiceValue', 'U') IS NOT NULL 
  DROP TABLE dbo.ServiceValue;

IF OBJECT_ID('dbo.Addresses', 'U') IS NOT NULL 
  DROP TABLE dbo.Addresses;

IF OBJECT_ID('dbo.ReferencePictures', 'U') IS NOT NULL 
  DROP TABLE dbo.ReferencePictures;

IF OBJECT_ID('dbo.UserProfessions', 'U') IS NOT NULL 
  DROP TABLE dbo.UserProfessions;

IF OBJECT_ID('dbo.Professions', 'U') IS NOT NULL 
  DROP TABLE dbo.Professions;

IF OBJECT_ID('dbo.UsersAvailableSchedule', 'U') IS NOT NULL 
  DROP TABLE dbo.UsersAvailableSchedule;

IF OBJECT_ID('dbo.UsersWorkZones', 'U') IS NOT NULL 
  DROP TABLE dbo.UsersWorkZones;

IF OBJECT_ID('dbo.UsersReferences', 'U') IS NOT NULL 
  DROP TABLE dbo.UsersReferences;

IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL 
  DROP TABLE dbo.Users;

CREATE TABLE dbo.Users (
	username varchar(50) NOT NULL PRIMARY KEY,
	password varchar(250) NOT NULL,
	firstname varchar(50) NOT NULL,
	lastname varchar(50) NOT NULL,
	lastname2 varchar(50) NOT NULL,
	email varchar(50) NOT NULL UNIQUE,
	phonenumber1 varchar(10) NOT NULL,
	phonenumber2 varchar(10),
	birthday date NOT NULL,
	profilePicture varchar(250),
	salt UNIQUEIDENTIFIER  NOT NULL
);

CREATE TABLE dbo.Addresses (
	username varchar(50) NOT NULL FOREIGN KEY (username) REFERENCES Users,
	provincia varchar(100) NOT NULL,
	canton varchar(100) NOT NULL,
	distrito varchar(100) NOT NULL,
	PRIMARY KEY (username)
);
GO

CREATE TABLE dbo.Professions (
	professionid integer NOT NULL PRIMARY KEY CHECK(professionid != 0),
	professionname varchar(100) NOT NULL
);

INSERT INTO dbo.Professions VALUES (1, 'Ingeniería de Software');
INSERT INTO dbo.Professions VALUES (2, 'Administración de empresas');
INSERT INTO dbo.Professions VALUES (3, 'Contabilidad');
INSERT INTO dbo.Professions VALUES (4, 'Ingeniería Industrial');

CREATE TABLE dbo.UserProfessions (
	username varchar(50) NOT NULL FOREIGN KEY (username) REFERENCES Users,
	professionid integer NOT NULL FOREIGN KEY (professionid) REFERENCES Professions,
	experienceyears integer NOT NULL,
	details text,
	costperhour varchar(10) DEFAULT 'A negociar'
	PRIMARY KEY (username, professionid)
);

CREATE TABLE dbo.ReferencePictures (
	username varchar(50) NOT NULL,
	professionid integer NOT NULL,
	imageURL varchar(max) NOT NULL,
	imageID integer NOT NULL,
	FOREIGN KEY (username, professionid) REFERENCES dbo.UserProfessions (username, professionid),
	PRIMARY KEY (username, professionid, imageID)
);

CREATE TABLE dbo.UsersAvailableSchedule (
	username varchar(50) NOT NULL FOREIGN KEY (username) REFERENCES Users,
	day int NOT NULL CHECK(day >= 0 and day <= 7),
	startTime TIME NOT NULL,
	endTime TIME NOT NULL,
	PRIMARY KEY (username, day)
);
GO

CREATE TABLE dbo.UsersWorkZones (
	username varchar(50) NOT NULL FOREIGN KEY (username) REFERENCES Users,
	provincia varchar(25) NOT NULL,
	canton varchar(25) NOT NULL,
	PRIMARY KEY (username, provincia, canton)
);

CREATE TABLE dbo.UsersReferences (
	username varchar(50) NOT NULL FOREIGN KEY (username) REFERENCES Users,
	referencenumber int NOT NULL,
	lastjob varchar(255) NOT NULL,
	firstname varchar(50) NOT NULL,
	lastname varchar(50) NOT NULL,
	lastname2 varchar(50) NOT NULL,
	phonenumber varchar(10) NOT NULL,
	PRIMARY KEY (username, referencenumber)
);
GO

CREATE TABLE dbo.ServiceValue (
	username varchar(50) NOT NULL FOREIGN KEY (username) REFERENCES Users,
	value int CHECK(value > 0 and value <=5)
);
GO

--FUNCTIONS
DROP FUNCTION IF EXISTS fAverageService;
GO
CREATE FUNCTION fAverageService (@username varchar(50))
RETURNS TABLE AS
RETURN 
	SELECT AVG(value) averageservicevalue FROM ServiceValue WHERE username = @username;
GO

DROP FUNCTION IF EXISTS fLogin;
GO
CREATE FUNCTION fLogin (@username varchar(50), @password varchar(50))
RETURNS TABLE AS
RETURN 
	SELECT U.username, U.firstname, U.lastname, U.lastname2,
		U.email, U.phonenumber1, U.phonenumber2, (SELECT CONVERT(VARCHAR(10), U.birthday, 103)) as birthday, U.profilePicture
	FROM dbo.Users U WHERE username = @username and U.password = HASHBYTES('SHA2_512', @password+CAST(U.salt AS NVARCHAR(36)));
GO

SELECT username, HASHBYTES('SHA2_512', password+CAST(salt AS NVARCHAR(36))) as password FROM Users

DROP FUNCTION IF EXISTS fUserAddress;
GO
CREATE FUNCTION fUserAddress (@username varchar(50))
RETURNS TABLE AS
RETURN 
	SELECT A.provincia, A.canton, A.distrito
	FROM dbo.Users U INNER JOIN dbo.Addresses A ON U.username = A.username
	WHERE U.username = @username;
GO

DROP FUNCTION IF EXISTS fUserProfessionReferencePictures;
GO
CREATE FUNCTION fUserProfessionReferencePictures (@username varchar(50), @professionid int)
RETURNS TABLE AS
RETURN 
	SELECT R.professionid, R.imageURL, R.imageID
	FROM dbo.ReferencePictures R INNER JOIN dbo.UserProfessions UP ON UP.username = R.username and UP.professionid = R.professionid
	WHERE R.username = @username and R.professionid = @professionid;
GO

DROP FUNCTION IF EXISTS fProfessionsByUser;
GO
CREATE FUNCTION fProfessionsByUser (@username varchar(50))
RETURNS TABLE AS
RETURN 
	SELECT UP.username, UP.professionid, UP.experienceyears, UP.details, UP.costperhour
	FROM dbo.UserProfessions UP
	WHERE UP.username = @username;
GO

DROP FUNCTION IF EXISTS fAvailableScheduleByUser;
GO
CREATE FUNCTION fAvailableScheduleByUser (@username varchar(50))
RETURNS TABLE AS
RETURN 
	SELECT UAS.day, CONVERT(varchar(5), UAS.startTime) as startTime, CONVERT(varchar(5), UAS.endTime) as endTime
	FROM dbo.UsersAvailableSchedule UAS
	WHERE UAS.username = @username;
GO

DROP FUNCTION IF EXISTS fWorkZonesByUser;
GO
CREATE FUNCTION fWorkZonesByUser (@username varchar(50))
RETURNS TABLE AS
RETURN 
	SELECT WZ.provincia, WZ.canton
	FROM dbo.UsersWorkZones WZ 
	WHERE WZ.username = @username;
GO

DROP FUNCTION IF EXISTS fReferencesByUser;
GO
CREATE FUNCTION fReferencesByUser (@username varchar(50))
RETURNS TABLE AS
RETURN 
	SELECT R.referencenumber, R.lastjob, R.firstname, R.lastname, R.lastname2, R.phonenumber
	FROM dbo.UsersReferences R
	WHERE R.username = @username;
GO

DROP FUNCTION IF EXISTS dbo.fGetProfessions;
GO
CREATE FUNCTION dbo.fGetProfessions ()
RETURNS TABLE AS
RETURN 
	SELECT * FROM Professions;
GO

DROP FUNCTION IF EXISTS dbo.fSearchByProfession;
GO
CREATE FUNCTION dbo.fSearchByProfession (@professionid int)
RETURNS TABLE AS
RETURN
	SELECT U.username, U.firstname, U.lastname, U.lastname2, U.email, U.phonenumber1, U.phonenumber2,
		(SELECT CONVERT(VARCHAR(10), U.birthday, 103)) as birthday, U.profilePicture
	FROM dbo.Users U INNER JOIN dbo.UserProfessions P ON U.username = P.username
	WHERE P.professionid = @professionid;
GO

DROP FUNCTION IF EXISTS dbo.fSearchByWorkZone;
GO
CREATE FUNCTION dbo.fSearchByWorkZone (@provincia varchar(50), @canton varchar(100))
RETURNS TABLE AS
RETURN
	SELECT U.username, U.firstname, U.lastname, U.lastname2, U.email, U.phonenumber1, U.phonenumber2,
		(SELECT CONVERT(VARCHAR(10), U.birthday, 103)) as birthday, U.profilePicture
	FROM dbo.Users U INNER JOIN dbo.UsersWorkZones P ON U.username = P.username
	WHERE (P.provincia = @provincia and P.canton = @canton );
GO

DROP FUNCTION IF EXISTS dbo.fSearchByProfessionAndWorkZone;
GO
CREATE FUNCTION dbo.fSearchByProfessionAndWorkZone (@professionid int, @provincia varchar(50), @canton varchar(100))
RETURNS TABLE AS
RETURN
	SELECT U.username, U.firstname, U.lastname, U.lastname2, U.email, U.phonenumber1, U.phonenumber2,
		(SELECT CONVERT(VARCHAR(10), U.birthday, 103)) as birthday, U.profilePicture
	FROM dbo.Users U INNER JOIN 
		(SELECT * FROM dbo.fSearchByProfession(@professionid) 
			INTERSECT
		 SELECT * FROM dbo.fSearchByWorkZone(@provincia, @canton)
		) S ON U.username = S.username;
GO

DROP FUNCTION IF EXISTS dbo.fSearchAllPeople;
GO
CREATE FUNCTION dbo.fSearchAllPeople ()
RETURNS TABLE AS
RETURN
	SELECT U.username, U.firstname, U.lastname, U.lastname2, U.email, U.phonenumber1, U.phonenumber2,
		(SELECT CONVERT(VARCHAR(10), U.birthday, 103)) as birthday, U.profilePicture
	FROM dbo.Users U;
GO

--PROCEDURES
DROP PROCEDURE IF EXISTS pRegisterUser;
GO
CREATE PROCEDURE pRegisterUser(
	@username varchar(50),
	@password varchar(25),
	@firstname varchar(50),
	@lastname varchar(50),
	@lastname2 varchar(50),
	@email varchar(50),
	@phonenumber1 varchar(10),
	@phonenumber2 varchar(10),
	@birthday_day int,
	@birthday_month int,
	@birthday_year int,
	@provincia varchar(100),
	@canton varchar(100),
	@distrito varchar(100)
) AS
BEGIN
	SET NOCOUNT ON
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	DECLARE @salt UNIQUEIDENTIFIER = NEWID();
	BEGIN TRY
		INSERT INTO Users VALUES (@username, HASHBYTES('SHA2_512', @password+CAST(@salt AS NVARCHAR(36))), 
								@firstname, @lastname, @lastname2, @email, @phonenumber1, @phonenumber2,
								DATEFROMPARTS(@birthday_year, @birthday_month, @birthday_day), NULL, @salt);
		INSERT INTO Addresses VALUES (@username, @provincia, @canton, @distrito);
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS pSetProfilePicture;
GO
CREATE PROCEDURE pSetProfilePicture(
	@username varchar(50),
	@imageURL varchar(MAX)
) AS
BEGIN
	SET NOCOUNT ON
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	BEGIN TRY
		UPDATE dbo.Users SET profilePicture = @imageURL
		WHERE username = @username;
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS pRemoveReferencePictureByUsernameAndIDs;
GO
CREATE PROCEDURE pRemoveReferencePictureByUsernameAndIDs(
	@username varchar(50),
	@professionid int,
	@imageIDs varchar(250)
) AS
BEGIN
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	DELETE FROM ReferencePictures WHERE username = @username and professionid = @professionid and (imageID IN (SELECT CAST(value as INT) FROM STRING_SPLIT(@imageIDs, '|')));
	SET @responseMessage = 'Success';
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS pAddReferencePicture;
GO
CREATE PROCEDURE pAddReferencePicture(
	@username varchar(50),
	@professionid int,
	@imageURL varchar(MAX)
) AS
BEGIN
	SET NOCOUNT ON
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	DECLARE @imageID int = (SELECT (MAX(imageID) + 1)
		FROM dbo.ReferencePictures WHERE username = @username);
	IF @imageID IS NULL SET @imageID = 1;
	BEGIN TRY
		INSERT INTO dbo.ReferencePictures VALUES (@username, @professionid, @imageURL, @imageID);
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @imageID as resultData, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS dbo.pAddUserProfession;
GO
CREATE PROCEDURE dbo.pAddUserProfession(
	@username varchar(50),
	@professionid int,
	@experienceyears int,
	@details text,
	@costperhour varchar(10)
) AS
BEGIN
	SET NOCOUNT ON
	DECLARE @responseMessage NVARCHAR(100);
	DECLARE @errorCode int;
	BEGIN TRY
		INSERT INTO dbo.UserProfessions VALUES (@username, @professionid, @experienceyears, @details, @costperhour);
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS dbo.pUpdateUserProfession;
GO
CREATE PROCEDURE dbo.pUpdateUserProfession(
	@username varchar(50),
	@professionid int,
	@experienceyears int,
	@details text,
	@costperhour varchar(10)
) AS
BEGIN
	SET NOCOUNT ON
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	BEGIN TRY
		UPDATE dbo.UserProfessions SET experienceyears = @experienceyears, details = @details, costperhour = @costperhour
		WHERE username = @username AND professionid = @professionid;
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS dbo.pRemoveUserProfessions;
GO
CREATE PROCEDURE dbo.pRemoveUserProfessions (
	@username varchar(50),
	@professionids varchar(255)
) AS
BEGIN
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	DELETE FROM dbo.UserProfessions 
	WHERE username = @username and (professionid IN (SELECT CAST(value as INT) FROM STRING_SPLIT(@professionids, '|')));
	SET @responseMessage = 'Success';
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS dbo.pUpdateUserAvailableSchedule;
GO
--day-startH:startM-endH:endM|
CREATE PROCEDURE dbo.pUpdateUserAvailableSchedule(
	@username varchar(50),
	@day int,
	@startTime varchar(50),
	@endTime varchar(50)
) AS
BEGIN
	SET NOCOUNT ON
	DECLARE @responseMessage NVARCHAR(max);
	DECLARE @errorCode int;
	BEGIN TRY
		INSERT INTO dbo.UsersAvailableSchedule (username, day, startTime, endTime) VALUES (@username, @day, @startTime, @endTime);
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS pClearAvailableScheduleByUser;
GO
CREATE PROCEDURE pClearAvailableScheduleByUser(
	@username varchar(50)
) AS
BEGIN
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	DELETE FROM dbo.UsersAvailableSchedule WHERE username = @username;
	SET @responseMessage = 'Success';
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS dbo.pAddUserWorkZone;
GO
CREATE PROCEDURE dbo.pAddUserWorkZone(
	@username varchar(50),
	@provincia varchar(100),
	@canton varchar(100)
) AS
BEGIN
	SET NOCOUNT ON
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	BEGIN TRY
		INSERT INTO dbo.UsersWorkZones VALUES (@username, @provincia, @canton);
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS pRemoveUserWorkZone;
GO
CREATE PROCEDURE pRemoveUserWorkZone(
	@username varchar(50),
	@provincia varchar(100),
	@canton varchar(100)
) AS
BEGIN
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	DELETE FROM UsersWorkZones WHERE username = @username and provincia = @provincia and canton = @canton;
	SET @responseMessage = 'Success';
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS dbo.pAddUserReference;
GO
CREATE PROCEDURE dbo.pAddUserReference(
	@username varchar(50),
	@lastjob varchar(255),
	@firstname varchar(50),
	@lastname varchar(50),
	@lastname2 varchar(50),
	@phonenumber varchar(10)
) AS
BEGIN
	SET NOCOUNT ON
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	DECLARE @referenceid int = (SELECT (MAX(referencenumber) + 1)
		FROM dbo.UsersReferences WHERE username = @username);
	IF @referenceid IS NULL SET @referenceid = 1;
	BEGIN TRY
		INSERT INTO dbo.UsersReferences VALUES (@username, @referenceid, @lastjob, @firstname, @lastname, @lastname2, @phonenumber);
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @referenceid as resultData, @errorCode as errorCode;
END
GO


DROP PROCEDURE IF EXISTS pRemoveUserReferenceByIds;
GO
CREATE PROCEDURE pRemoveUserReferenceByIds(
	@username varchar(50),
	@referenceids varchar(255)
) AS
BEGIN
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	DELETE FROM dbo.UsersReferences 
		WHERE username = @username and (referencenumber IN (SELECT CAST(value as INT) FROM STRING_SPLIT(@referenceids, '|')));
	SET @responseMessage = 'Success';
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS pUpdateAddress;
GO
CREATE PROCEDURE pUpdateAddress(
	@username varchar(50),
	@provincia varchar(255),
	@canton varchar(255),
	@distrito varchar(255)
) AS
BEGIN
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	BEGIN TRY
		DELETE FROM dbo.Addresses WHERE username = @username;
		INSERT INTO dbo.Addresses VALUES (@username, @provincia, @canton, @distrito);
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

DROP PROCEDURE IF EXISTS pUpdateUser;
GO
CREATE PROCEDURE pUpdateUser(
	@username varchar(50),
	@email varchar(255),
	@phonenumber1 varchar(255),
	@phonenumber2 varchar(255)
) AS
BEGIN
	DECLARE @responseMessage NVARCHAR(50);
	DECLARE @errorCode int;
	BEGIN TRY
		UPDATE dbo.Users SET email = @email, phonenumber1 = @phonenumber1, phonenumber2 = @phonenumber2 
		WHERE username = @username;
		SET @responseMessage = 'Success';
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE();
		SET @errorCode = ERROR_NUMBER();
	END CATCH
	SELECT @responseMessage as responseMessage, @errorCode as errorCode;
END
GO

--TESTING
--INSERT INTO dbo.Users VALUES ('LuisMJ', 'luisito138', 'Luis', 'Molina', 'Juárez', 'luisfermjua@gmail.com',
--								'61638663', '62055706', '1997-11-20');
EXEC dbo.pRegisterUser
	@username = 'LuisMJ',
	@password = 'luisito138', 
	@firstname = 'Luis', 
	@lastname = 'Molina', 
	@lastname2 = 'Juárez',
	@email = 'luisfermjua@gmail.com',
	@phonenumber1 = '61638663',
	@phonenumber2 ='62055706',
	@birthday_day = '20', 
	@birthday_month = '11',
	@birthday_year = '1997',
	@provincia = 'Limón',
	@canton = 'Matina',
	@distrito = 'Matina';
EXEC dbo.pRegisterUser
	@username = 'LuisF',
	@password = 'luisito138', 
	@firstname = 'Luis', 
	@lastname = 'Molina', 
	@lastname2 = 'Juárez',
	@email = 'luisfermjua5@gmail.com',
	@phonenumber1 = '61638663',
	@phonenumber2 ='62055706',
	@birthday_day = '20', 
	@birthday_month = '11',
	@birthday_year = '1997',
	@provincia = 'Limón',
	@canton = 'Matina',
	@distrito = 'Matina';
EXEC dbo.pAddUserProfession 
	@username = 'LuisMJ',
	@professionid = 3,
	@experienceyears = 2,
	@details = 'Ninguno',
	@costperhour = '12000';
--EXEC dbo.pRemoveUserProfession
	--@username = 'LuisMJ',
	--@professionid = 1;


--INSERT INTO UsersAvailableSchedule (username, day) VALUES ('LuisMJ', 'Lunes');
--INSERT INTO UsersWorkZones VALUES ('LuisMJ', 'Limón', 'Matina');
--INSERT INTO UsersReferences VALUES ('LuisMJ', 1, 'Michelle', 'Alvarado', 'Zuñiga', '62055706');
SELECT * FROM ReferencePictures;
SELECT * FROM UserProfessions
SELECT * FROM UsersWorkZones;
--SELECT * FROM fLogin('LuisMJ', 'luisito138');
--SELECT * FROM fProfessionsByUser('LuisMJ');
SELECT * FROM fWorkZonesByUser('LuisMJ');
--SELECT * FROM fReferencesByUser('LuisMJ');
--SELECT * FROM Users WHERE username = 'LuisMJ' and password = 'luisito138';

--- Search Functions

SELECT * FROM dbo.fLogin('LuisMJ', 'luisito138');

SELECT * FROM UsersAvailableSchedule;