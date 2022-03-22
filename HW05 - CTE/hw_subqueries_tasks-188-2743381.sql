/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

Select PersonID, FullName
From Application.People
Where IsSalesPerson = 1 and NOT Exists (Select SalespersonPersonID, InvoiceDate
From Sales.Invoices
Where Invoices.SalespersonPersonID = People.PersonID and InvoiceDate = '2015-07-04')

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
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
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

WITH CustomerTransactionsCTE (TransactionAmount, CustomerID) AS 
(
     SELECT TOP 14 TransactionAmount, CustomerID -- если выставлю топ 5, запрос выдает результат только по первым 5 строкам. ID Клиентов находятся в диапазоне 15 строк, вывести их точечно затрудняюсь. По этому выставил топ 14
	 FROM Sales.CustomerTransactions
	 ORDER BY TransactionAmount desc
)
Select p.PersonID, p.FullName, t.TransactionAmount
FROM Application.People AS p
     JOIN CustomerTransactionsCTE AS t
		ON p.PersonID = t.CustomerID;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/



WITH SalesOrderLinesCTE AS  -- топ 3 дорогих товаров
(
Select DISTINCT TOP 3 UnitPrice, StockItemID
FROM Sales.OrderLines
ORDER BY UnitPrice DESC
)
SELECT CityID, CityName, StockitemID, FullName, PickedByPersonID  -- Пытался разделить следующие джойны с СТЕ, возникли трудности. У вас нет примера выполненого задания другим способом? (для ознакомления, возможно увижу свои ошибки)
FROM SalesOrderLinesCTE
LEFT JOIN Sales.Orders o ON o.OrderID = OrderID
INNER JOIN Sales.Customers sc ON sc.CustomerID = o.CustomerID
INNER JOIN Application.Cities c ON sc.DeliveryCityID = CityID
INNER JOIN Application.People p ON p.PersonID = PickedByPersonID -- PickedByPersonID - есть нулевые значения, их нужно вывести?

-- Опциональное задание попробую пройти чуть позднее, мне необходимо повторно ознакомиться с темой чтения планов запросов. Пока есть пробелы по этой теме.

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

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

TODO: напишите здесь свое решение
