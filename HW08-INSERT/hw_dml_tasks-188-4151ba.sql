/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

SELECT *
From Sales.Customers

Declare
@BillToCustomerID INT,
@WebsiteURL nvarchar(256) = 'http://www.microsoft.com/'

SELECT @BillToCustomerID = CustomerID --@PostalPostalCode = DeliveryPostalCode
FROM Sales.Customers

Insert into Sales.Customers (CustomerID, 
CustomerName, 
BillToCustomerID, 
CustomerCategoryID, 
PrimaryContactPersonID, 
DeliveryMethodID, 
DeliveryCityID, 
PostalCityID, 
AccountOpenedDate, 
StandardDiscountPercentage, 
IsStatementSent, 
IsOnCreditHold, 
PaymentDays, 
PhoneNumber, 
FaxNumber, 
WebsiteURL, 
DeliveryAddressLine1,
DeliveryPostalCode, 
PostalAddressLine1,
PostalPostalCode,
LastEditedBy, 
ValidFrom, 
ValidTo)
Values (NEXT VALUE FOR Sequences.CustomerID, 'Adams Felix', @BillToCustomerID, '5', '3261', '3', '19881', '19881', '2016-05-07', '0.000', '0', '0', '7', '(206) 555-0100', '(206) 555-0101', @WebsiteURL, 'Shop 12', '90243','PO Box 8112','90243','1',default, default),
       (NEXT VALUE FOR Sequences.CustomerID, 'Misha Fox', @BillToCustomerID, '5', '3261', '3', '19881', '19881', '2016-05-07', '0.000', '0', '0', '7', '(206) 555-0100', '(206) 555-0101', @WebsiteURL, 'Shop 12', '90243','PO Box 8112','90243','1',default, default),
	   (NEXT VALUE FOR Sequences.CustomerID, 'Sasha Marloy', @BillToCustomerID, '5', '3261', '3', '19881', '19881', '2016-05-07', '0.000', '0', '0', '7', '(206) 555-0100', '(206) 555-0101', @WebsiteURL, 'Shop 12', '90243','PO Box 8112','90243','1',default, default),
	   (NEXT VALUE FOR Sequences.CustomerID, 'Tony Fergyuson', @BillToCustomerID, '5', '3261', '3', '19881', '19881', '2016-05-07', '0.000', '0', '0', '7', '(206) 555-0100', '(206) 555-0101', @WebsiteURL, 'Shop 12', '90243','PO Box 8112','90243','1',default, default),
	   (NEXT VALUE FOR Sequences.CustomerID, 'Petr Yan', @BillToCustomerID, '5', '3261', '3', '19881', '19881', '2016-05-07', '0.000', '0', '0', '7', '(206) 555-0100', '(206) 555-0101', @WebsiteURL, 'Shop 12', '90243','PO Box 8112','90243','1',default, default)

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

Delete 
From Sales.Customers
Where CustomerName = 'Petr Yan'

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

Update Sales.Customers
SET 
	PhoneNumber = '(303) 555-0101'
OUTPUT inserted.PhoneNumber as new_phon
WHERE CustomerID = '1121'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

Create table Sales.CustomersCopy
(
       [CustomerID] INT
      ,[CustomerName] NVARCHAR(100)
      ,[CreditLimit] Decimal(18,2)
);

Insert Sales.CustomersCopy
Select CustomerID
      ,CustomerName
      ,CreditLimit
From Sales.Customers

Update Sales.CustomersCopy
set CreditLimit = '2500'


Merge Sales.Customers AS Cusomers
Using Sales.CustomersCopy as CustomersCopy
ON (Cusomers.Customerid = CustomersCopy.Customerid)
WHEN MATCHED THEN 
             UPDATE SET CreditLimit = CustomersCopy.CreditLimit
WHEN NOT MATCHED THEN
                 INSERT (CreditLimit) 
                 VALUES (CustomersCopy.CreditLimit)
output inserted.CreditLimit;



/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
SELECT @@SERVERNAME

Exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.OrderLines" out  "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Sales.OrderLines.txt" -T -w -t"@eu&$1&" -S LAPTOP-S837TRMA'

CREATE TABLE WideWorldImporters.Sales.OrderLinesCopy(
	[OrderLineID] [int] NOT NULL,
	[OrderID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[PickedQuantity] [int] NOT NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Sales_OrderLines_Copy] PRIMARY KEY CLUSTERED 
(
	[OrderLineID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [USERDATA]
) ON [USERDATA]

BULK INSERT  WideWorldImporters.Sales.OrderLinesCopy
				   FROM "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Sales.OrderLines.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '@eu&$1&',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );

select Count(*) from WideWorldImporters.Sales.OrderLinesCopy;

DROP TABLE Sales.OrderLinesCopy