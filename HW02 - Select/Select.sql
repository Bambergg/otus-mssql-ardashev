/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/


SELECT StockItemID, StockItemName
FROM [Warehouse].[StockItems]
WHERE StockItemName like ('Animal%') 
OR StockItemName like ('%urgent%')	

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT s.SupplierID, s.Suppliername
FROM [Purchasing].[Suppliers] s LEFT JOIN [Purchasing].[PurchaseOrders] p
ON p.SupplierID = s.SupplierID
WHERE p.SupplierID is null


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

--Возникли сложности как выполнить условие треть года, пока сделал без него

SELECT o.OrderID, i.UnitPrice, i.Quantity, c.CustomerName as Customer,
CONVERT(nvarchar,o.OrderDate, 104) AS OrderDate,
DATENAME(month,o.OrderDate) AS OrderMonth,
DATEPART(quarter,o.OrderDate) AS OrderQuarter, 
CONVERT(nvarchar,o.PickingCompletedWhen, 104) AS Datacompeted
FROM [Sales].[Orders] o 
JOIN [Sales].[OrderLines] i on o.OrderID = i.OrderID
JOIN [Sales].[Customers] c on c.CustomerID = o.CustomerID
Where (UnitPrice > 100) or (Quantity >20)
Order by OrderDate asc, OrderQuarter asc

-- Вариант с постраничной выборкой 

SELECT o.OrderID, i.UnitPrice, i.Quantity, c.CustomerName as Customer,
CONVERT(nvarchar,o.OrderDate, 104) AS OrderDate,
DATENAME(month,o.OrderDate) AS OrderMonth,
DATEPART(quarter,o.OrderDate) AS OrderQuarter,
CONVERT(nvarchar,o.PickingCompletedWhen, 104) AS Datacompeted
FROM [Sales].[Orders] o 
JOIN [Sales].[OrderLines] i on o.OrderID = i.OrderID
JOIN [Sales].[Customers] c on c.CustomerID = o.CustomerID
Where (UnitPrice > 100) or (Quantity >20)
Order by OrderDate asc, OrderQuarter asc

OFFSET 1100 ROWS FETCH FIRST 100 ROWS ONLY


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

Select m.DeliveryMethodName, o.ExpectedDeliveryDate, SupplierName, p.FullName as ContactPerson
From [Purchasing].[Suppliers] s
JOIN [Purchasing].[PurchaseOrders] o on o.SupplierID = s.SupplierID
JOIN [Application].[DeliveryMethods] m on o.DeliveryMethodID = m.DeliveryMethodID
JOIN [Application].[People] p on p.PersonID = o.ContactPersonID
Where ExpectedDeliveryDate BETWEEN '2013-01-01' and '2013-01-31' and (m.DeliveryMethodName like 'Air Freight' or m.DeliveryMethodName like 'Refrigerated Air Freight')
Order by DeliveryMethodName

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

Select top 10 t.TransactionDate, c.CustomerName, p.FullName as PersonName
From [Sales].[Customers] c
JOIN [Sales].[Invoices] i on c.CustomerID = i.CustomerID
JOIN [Application].[People] p on p.PersonID = i.SalespersonPersonID
JOIN [Sales].[CustomerTransactions] t on c.CustomerID = t.CustomerID
Order by t.TransactionDate desc


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

Select distinct PersonID as CustomerId, s.StockItemName, FullName, p.PhoneNumber, p.FaxNumber
from [Warehouse].[StockItems] s
JOIN [Sales].[OrderLines] o on s.StockItemID = o.StockItemID
JOIN [Sales].[Orders] r on r.OrderID = o.OrderID
JOIN [Sales].[Customers] t on t.CustomerID = r.CustomerID
JOIN [Application].[People] p on p.PersonID = t.CustomerID
Where s.StockItemName = 'Chocolate frogs 250g'
order by CustomerId 


