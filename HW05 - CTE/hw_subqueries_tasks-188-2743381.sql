/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "03 - ����������, CTE, ��������� �������".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ��� ���� �������, ��� ��������, �������� ��� �������� ��������:
--  1) ����� ��������� ������
--  2) ����� WITH (��� ����������� ������)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), 
� �� ������� �� ����� ������� 04 ���� 2015 ����. 
������� �� ���������� � ��� ������ ���. 
������� �������� � ������� Sales.Invoices.
*/

Select PersonID, FullName
From Application.People
Where IsSalesPerson = 1 and NOT Exists (Select SalespersonPersonID, InvoiceDate
From Sales.Invoices
Where Invoices.SalespersonPersonID = People.PersonID and InvoiceDate = '2015-07-04')

/*
2. �������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. 
�������: �� ������, ������������ ������, ����.
*/

SELECT StockItemID, StockItemName, UnitPrice
FROM Warehouse.StockItems
WHERE UnitPrice <= all (
SELECT UnitPrice
FROM Warehouse.StockItems)

SELECT 
StockItemID, 
StockItemName,  
	(SELECT 
		MIN(UnitPrice) 
	FROM Warehouse.StockItems) AS MINPrice
FROM Warehouse.StockItems


/*
3. �������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� 
�� Sales.CustomerTransactions. 
����������� ��������� �������� (� ��� ����� � CTE). 
*/

WITH CustomerTransactionsCTE (TransactionAmount, CustomerID) AS 
(
     SELECT TOP 14 TransactionAmount, CustomerID -- ���� �������� ��� 5, ������ ������ ��������� ������ �� ������ 5 �������. ID �������� ��������� � ��������� 15 �����, ������� �� ������� �����������. �� ����� �������� ��� 14
	 FROM Sales.CustomerTransactions
	 ORDER BY TransactionAmount desc
)
Select p.PersonID, p.FullName, t.TransactionAmount
FROM Application.People AS p
     JOIN CustomerTransactionsCTE AS t
		ON p.PersonID = t.CustomerID;

/*
4. �������� ������ (�� � ��������), � ������� ���� ���������� ������, 
�������� � ������ ����� ������� �������, � ����� ��� ����������, 
������� ����������� �������� ������� (PackedByPersonID).
*/



WITH SalesOrderLinesCTE AS  -- ��� 3 ������� �������
(
Select DISTINCT TOP 3 UnitPrice, StockItemID
FROM Sales.OrderLines
ORDER BY UnitPrice DESC
)
SELECT CityID, CityName, StockitemID, FullName, PickedByPersonID  -- ������� ��������� ��������� ������ � ���, �������� ���������. � ��� ��� ������� ����������� ������� ������ ��������? (��� ������������, �������� ����� ���� ������)
FROM SalesOrderLinesCTE
LEFT JOIN Sales.Orders o ON o.OrderID = OrderID
INNER JOIN Sales.Customers sc ON sc.CustomerID = o.CustomerID
INNER JOIN Application.Cities c ON sc.DeliveryCityID = CityID
INNER JOIN Application.People p ON p.PersonID = PickedByPersonID -- PickedByPersonID - ���� ������� ��������, �� ����� �������?

-- ������������ ������� �������� ������ ���� �������, ��� ���������� �������� ������������ � ����� ������ ������ ��������. ���� ���� ������� �� ���� ����.

-- ---------------------------------------------------------------------------
-- ������������ �������
-- ---------------------------------------------------------------------------
-- ����� ��������� ��� � ������� ��������� ������������� �������, 
-- ��� � � ������� ��������� �����\���������. 
-- �������� ������������������ �������� ����� ����� SET STATISTICS IO, TIME ON. 
-- ���� ������� � ������� ��������, �� ����������� �� (����� � ������� ����� ��������� �����). 
-- �������� ���� ����������� �� ������ �����������. 

-- 5. ���������, ��� ������ � ������������� ������

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: �������� ����� ���� �������
