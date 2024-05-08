CREATE DATABASE QuanLyQuanCafe
GO
USE QuanLyQuanCafe
GO
-- Food
-- Table
-- FoodCategory
-- Account
-- Bill
-- BillInfo
CREATE TABLE TableFood
(
	id INT IDENTITY PRIMARY KEY,
	name NVARCHAR(100) NOT NULL DEFAULT N'Bàn chưa có tên',
	status NVARCHAR(100) NOT NULL DEFAULT N'Trống'	-- Trống || Có người
)
GO
CREATE TABLE Account
(
	
	UserName NVARCHAR(100) PRIMARY KEY,	
	DisplayName NVARCHAR(100) NOT NULL DEFAULT N'Kter',
	PassWord NVARCHAR(1000) NOT NULL DEFAULT 0,
	Type INT NOT NULL  DEFAULT 0 -- 1: admin && 0: staff
)
GO
CREATE TABLE FoodCategory
(
	id INT IDENTITY PRIMARY KEY,
	name NVARCHAR(100) NOT NULL DEFAULT N'Chưa đặt tên'
)
GO
CREATE TABLE Food
(
	id INT IDENTITY PRIMARY KEY,
	name NVARCHAR(100) NOT NULL DEFAULT N'Chưa đặt tên',
	idCategory INT NOT NULL,
	price FLOAT NOT NULL DEFAULT 0
	
	FOREIGN KEY (idCategory) REFERENCES dbo.FoodCategory(id)
)
GO
CREATE TABLE Bill
(
	id INT IDENTITY PRIMARY KEY,
	DateCheckIn DATE NOT NULL DEFAULT GETDATE(),
	DateCheckOut DATE,
	idTable INT NOT NULL,
	status INT NOT NULL DEFAULT 0 -- 1: đã thanh toán && 0: chưa thanh toán
	discount INT DEFAULT 0
	totalPrice FLOAT DEFAULT 0
	FOREIGN KEY (idTable) REFERENCES dbo.TableFood(id)
)
GO
CREATE TABLE BillInfo
(
	id INT IDENTITY PRIMARY KEY,
	idBill INT NOT NULL,
	idFood INT NOT NULL,
	count INT NOT NULL DEFAULT 0
	
	FOREIGN KEY (idBill) REFERENCES dbo.Bill(id),
	FOREIGN KEY (idFood) REFERENCES dbo.Food(id)
)
GO
Insert into dbo.Account (UserName, DisplayName , PassWord ,Type )
Values (N'K9',--UserName - nvarchar(100)
	N'RongK9',--DisplayName - nvarchar(100)
	N'1', -- PassWord - nvarchar(1000)
	1)
Insert into dbo.Account (UserName, DisplayName , PassWord ,Type )
Values (N'staff',--UserName - nvarchar(100)
	N'Nhân viên',--DisplayName - nvarchar(100)
	N'1', -- PassWord - nvarchar(1000)
	0)
GO
Create proc USP_GetAccountByUserName --User Procedure
@userName nvarchar(100)
as
Begin
	select * from dbo.Account where UserName = @UserName
End
GO
Create proc USP_GetAccountByUserNameAndDisplayName
@userName nvarchar(100),
@displayName nvarchar(100)
as
Begin
	select * from dbo.Account where UserName = @userName and DisplayName = @displayName 
End
GO
Create proc USP_Login
@userName nvarchar(100),
@passWord nvarchar(100)
as
Begin
	select * from dbo.Account where UserName = @userName and PassWord = @passWord  
End
GO 
---- thêm bàn
declare @i INT=1
while @i<=10
Begin
	insert dbo.TableFood (name  )values (N'Bàn ' + cast(@i as nvarchar(100)))
	set @i = @i +1;
end
go
create proc USP_GetTableList
as select * from dbo.TableFood 
go
--Thêm category
insert dbo.FoodCategory (name) values (N'Hải sản'),(N'Nông sản'),(N'Lâm sản'),(N'Sản sản')
--Thêm món ăn
insert dbo.Food(name , idCategory, price ) values
(N'Mực một nắng',2,120000),
(N'Nghêu hấp xả',2,60000),
(N'Vú dê nướng',3,70000),
(N'Heo rừng nướng muối ớt',4,80000),
(N'Côm chiên mushi',5,40000)
 go
 --Thêm bill
 insert dbo.Bill(DateCheckIn , DateCheckOut , idTable , status ) values
 (GETDATE() , NULL, 1,0),
 (GETDATE() , NULL, 2,0),
 (GETDATE() , GETDATE(), 2,1)
 go
 --Thêm billInfo
 insert dbo.BillInfo (idBill , idFood , count ) values
 (1,1,2),  (1,3,4),(1,5,1),(2,1,2),(2,6,2),(3,5,2)
 go

 
 create proc USP_InsertBill
 @idTable INT
 As
 Begin
	insert dbo.Bill(DateCheckIn,DateCheckOut,idTable,status, discount) Values
	(GETDATE(), NULL, @idTable,0,0)
 End
 go
create proc USP_InsertBillInfo
 @idBill INT, @idFood INT, @count INT
 As
 Begin
	declare @isExitBillInfo INT;
	declare @foodCount INT=1
	select @isExitBillInfo = ID, @foodCount=b.count  from dbo.BillInfo as b where idBill  = @idBill and idfood = @idFood  
	if(@isExitBillInfo>0)
	Begin
		DECLARE @newCount INT = @foodCount + @count
		if (@newCount>0)
			UPDATE dbo.BillInfo SET count= @foodCount+ @count  WHERE  idFood = @idFood 
		else
			DELETE dbo.BillInfo WHERE idBill=@idBill AND idFood = @idFood 
	End
	else
	Begin
		insert dbo.BillInfo (idBill , idFood , count ) values
			(@idBill,@idFood,@count)
	end
 End
 go

 CREATE TRIGGER UTG_UpdateBillInfo
 ON dbo.BillInfo FOR INSERT, UPDATE
 AS
 BEGIN
	DECLARE @idBill INT
	SELECT @idBill= idBill FROM inserted 
	DECLARE @idTable INT
	SELECT @idTable = idTable FROM dbo.Bill WHERE id = @idBill and status=0
	UPDATE dbo.TableFood SET status=N'Có người' WHERE id = @idTable
 END
 GO
 CREATE TRIGGER UTG_UpdateTable
 ON dbo.TableFood FOR UPDATE
 AS
 BEGIN
	   DECLARE @idTable INT
	   DECLARE @status NVARCHAR(100)
	   SELECT @idTable = id , @status = Inserted.status FROM Inserted
	   DECLARE @idBill INT
	   SELECT @idBill = id FROM dbo.Bill WHERE idTable = @idTable AND status=0
	   DECLARE @countBillInfo INT
	   SELECT @countBillInfo=COUNT(*) FROM dbo.BillInfo WHERE idBill = @idBill
	   IF (@countBillInfo>0 )--AND @status<>N'Có người')
			UPDATE dbo.TableFood SET status=N'Có người' WHERE id = @idTable
		ELSE --IF (@countBillInfo>0 AND @status<>N'Trống')
			UPDATE dbo.TableFood SET status=N'Trống' WHERE id = @idTable
 END 
 GO
 
 CREATE TRIGGER UTG_UpdateBill
 ON dbo.Bill FOR UPDATE
 AS
 BEGIN
	DECLARE @idBill INT
	SELECT @idBill= id FROM inserted 
	DECLARE @idTable INT
	SELECT @idTable = idTable FROM dbo.Bill WHERE id = @idBill 
	DECLARE @count int = 0
	SELECT @count = COUNT(*) FROM dbo.Bill WHERE idTable = @idTable and status =0
	IF (@count=0)
		UPDATE dbo.TableFood SET status = N'Trống' WHERE id = @idTable
 END
 GO

 CREATE PROC USP_SwitchTable
 @idTable1 int , @idTable2 int
 AS
 BEGIN
	 DECLARE @idFirstBill int 
	 DECLARE @idSeconrdBill INT

	 DECLARE @isFirstTablEmty INT=1
	 DECLARE @isSecondTablEmty INT=1

     SELECT @idSeconrdBill=id FROM dbo.Bill WHERE idTable = @idTable2 AND status = 0
	  SELECT @idFirstBill=id FROM dbo.Bill WHERE idTable = @idTable1 AND status = 0
	  IF ( @idFirstBill IS NULL)
	  BEGIN
		INSERT dbo.Bill
		(
		    DateCheckIn,
		    DateCheckOut,
		    idTable,
		    status,
		    discount
		)
		VALUES
		(   GETDATE(), -- DateCheckIn - date
		    NULL, -- DateCheckOut - date
		    @idTable1,         -- idTable - int
		    0,         -- status - int
		    0          -- discount - int
		    )
		SELECT @idFirstBill = MAX(id) FROM dbo.Bill WHERE idTable = @idTable1 AND status=0
		

	  END
	  SELECT @isFirstTablEmty = COUNT(*) FROM dbo.BillInfo WHERE idBill = @idFirstBill

	IF ( @idSeconrdBill IS NULL)
	  BEGIN
		INSERT dbo.Bill
		(
		    DateCheckIn,
		    DateCheckOut,
		    idTable,
		    status,
		    discount
		)
		VALUES
		(   GETDATE(), -- DateCheckIn - date
		    NULL, -- DateCheckOut - date
		    @idTable2,         -- idTable - int
		    0,         -- status - int
		    0          -- discount - int
		    )
		SELECT @idSeconrdBill = MAX(id) FROM dbo.Bill WHERE idTable = @idTable2 AND status=0
		
     END
	   SELECT @isSecondTablEmty = COUNT(*) FROM dbo.BillInfo WHERE idBill = @idSeconrdBill
	 SELECT id INTO IDBillInfoTable FROM dbo.BillInfo WHERE idBill = @idSeconrdBill
	 UPDATE dbo.BillInfo SET idBill = @idSeconrdBill WHERE idBill = @idFirstBill
	 UPDATE dbo.BillInfo SET idBill = @idFirstBill WHERE id IN (SELECT * FROM dbo.IDBillInfoTable)

	 DROP TABLE dbo.IDBillInfoTable

	 IF (@isFirstTablEmty=0)
		UPDATE dbo.TableFood SET status = N'Trống' WHERE id = @idTable2
	IF (@isSecondTablEmty=0)
		UPDATE dbo.TableFood SET status = N'Trống' WHERE id = @idTable1
 END 
 GO
CREATE PROC USP_GetListBillByDate
  @checkIn date, @checkOut date
  AS
  BEGIN
	  SELECT t.name AS [Tên bàn],b.totalPrice AS [Tổng tiền], DateCheckIn AS [Ngày vào], DateCheckOut AS [Ngày ra], discount AS [Giảm giá] 
	  FROM dbo.Bill AS b, dbo.TableFood AS t 
	  WHERE DateCheckIn>=@checkIn AND DateCheckOut<=@checkOut AND b.status=1
			AND t.id = b.idTable 
  END
GO

SELECT * FROM dbo.Account
GO

CREATE PROC USP_UpdateAccount
@userName NVarchar(100), @displayName NVARCHAR(100), @passWord NVARCHAR(100), @newPassword NVARCHAR(100)
AS
BEGIN
	DECLARE @isRightPass INT
	SELECT @isRightPass = COUNT(*) FROM dbo.Account WHERE userName = @userName AND PassWord = @passWord
    IF ( @isRightPass=1)
	BEGIN
		IF ( @newPassword = NULL OR @newPassword='')
		BEGIN
			UPDATE dbo.Account SET DisplayName = @displayName WHERE UserName = @userName
		END
		ELSE
		BEGIN
			UPDATE dbo.Account SET DisplayName = @displayName, PassWord=@newPassword WHERE UserName = @userName
		END
	END
END
GO
CREATE PROC USP_GetListBillByDateAndPage
  @checkIn date, @checkOut DATE, @page INT
  AS
  BEGIN
	  DECLARE @pageRows INT =10
	  DECLARE @selectRows INT = @pageRows* @page 
	  DECLARE @exceptRows INT = (@page -1)*@pageRows
	  
	  ;WITH BillShow as (SELECT b.id, t.name AS [Tên bàn],b.totalPrice AS [Tổng tiền], DateCheckIn AS [Ngày vào], DateCheckOut AS [Ngày ra], discount AS [Giảm giá] 
	  FROM dbo.Bill AS b, dbo.TableFood AS t 
	  WHERE DateCheckIn>=@checkIn AND DateCheckOut<=@checkOut AND b.status=1
			AND t.id = b.idTable )
	  
	  SELECT TOP (@selectRows) * FROM BillShow
	  EXCEPT
	  SELECT TOP (@exceptRows) * FROM BillShow
  END
GO

CREATE PROC USP_GetNumBillByDate
  @checkIn date, @checkOut DATE
  AS
  BEGIN
	  SELECT  COUNT(*)
	  FROM dbo.Bill AS b, dbo.TableFood AS t 
	  WHERE DateCheckIn>=@checkIn AND DateCheckOut<=@checkOut AND b.status=1
			AND t.id = b.idTable
  END
GO
CREATE PROC USP_GetListBillByDateForReport
  @checkIn date, @checkOut date
  AS
  BEGIN
	  SELECT t.name ,b.totalPrice , DateCheckIn , DateCheckOut , discount  
	  FROM dbo.Bill AS b, dbo.TableFood AS t 
	  WHERE DateCheckIn>=@checkIn AND DateCheckOut<=@checkOut AND b.status=1
			AND t.id = b.idTable 
  END
GO
