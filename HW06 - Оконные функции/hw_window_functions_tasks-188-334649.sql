/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/


/*Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/


SELECT Invoices.InvoiceId, people.FullName, Invoices.InvoiceDate, Invoices.CustomerID, trans.TransactionAmount,
SUM(trans.TransactionAmount) OVER (ORDER BY MONTH(Invoices.InvoiceDate)) as MaxTransactionAmount -- Затрудняюсь, с 2016г счет начинается заного по месяцам.
FROM Sales.Invoices as Invoices
	join Sales.CustomerTransactions as trans
		ON Invoices.InvoiceID = trans.InvoiceID
		 join Application.People as people
		     ON Invoices.CustomerID = people.PersonID
WHERE Invoices.InvoiceDate > '2014-12-31'
ORDER BY Invoices.InvoiceDate, Invoices.InvoiceId

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

SELECT *
FROM 
    (
    Select l.StockItemID, 
	      SUM(l.Quantity) as Number, 
		  MONTH(i.InvoiceDate) as Month,
          ROW_NUMBER() OVER (PARTITION BY MONTH(i.InvoiceDate) ORDER BY SUM(l.Quantity) DESC) AS ProductTransRank
    From Sales.InvoiceLines l
        JOIN Sales.Invoices i on i.InvoiceID = l.InvoiceID
            Where InvoiceDate between '2016-01-01' and '2016-12-31'
                 Group By l.StockItemID, MONTH(i.InvoiceDate)
    ) AS tbl
WHERE ProductTransRank <= 2
Order By Month, Number DESC


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

-- посчитайте общее количество товаров в зависимости от первой буквы названия товара - НЕ ПОЛУЧИЛОСЬ

SELECT StockItemID, StockItemName, UnitPrice, nm,
       ROW_NUMBER() OVER (partition by nm order by nm) AS number_name,
       COUNT(StockItemName) OVER() AS TotalItem,
       LEAD(StockItemID,1,0) OVER (ORDER BY StockItemName) as Follow,
       LAG(StockItemID,1,0) OVER (ORDER BY StockItemName) as Prev,
       LAG(StockItemName,2,'No items') OVER (ORDER BY StockItemName) as PrevItem,
       NTILE(30) OVER (ORDER BY TypicalWeightPerUnit) AS RankPerUnit
       FROM 
       (
          SELECT DISTINCT StockItems.StockItemID, StockItems.StockItemName, InvoiceLines.UnitPrice, StockItems.TypicalWeightPerUnit,
                          SUBSTRING(StockItems.StockItemName, 1,1) AS nm
          FROM [Warehouse].[StockItems] AS StockItems
               JOIN [Sales].[InvoiceLines] AS InvoiceLines ON StockItems.StockItemID = InvoiceLines.StockItemID
       ) AS tbl

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

Select top(1) with ties *From    (    Select i.SalespersonPersonID, p.FullName, i.CustomerID, a.FullName as NameCustomer, i.InvoiceDate, l.ExtendedPrice    From Sales.Invoices i         Join Application.People p on p.PersonID = i.SalespersonPersonID         Join Sales.InvoiceLines l on i.InvoiceID = l.InvoiceID         Join Application.People a on a.PersonID = i.CustomerID    ) AS tblOrder by row_number() OVER (partition by SalespersonPersonID order by InvoiceDate desc);


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

Select CustomerID, FullName, StockItemID, UnitPrice, InvoiceDateFrom        (       Select row_number() OVER (partition by CustomerID order by InvoiceDate DESC) as RN,              i.CustomerID, P.FullName, l.StockItemID, l.UnitPrice, i.InvoiceDate       From Sales.Invoices i            join Application.People p on p.PersonID = i.CustomerID            join Sales.InvoiceLines l on i.InvoiceID = l.InvoiceID        ) AS tblWHERE RN <= 2Order by CustomerID, UnitPrice DESC




Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 
