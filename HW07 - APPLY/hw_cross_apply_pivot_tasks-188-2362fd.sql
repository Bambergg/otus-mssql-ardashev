/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
Select InvoiceMonth, [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND]
       From (
            SELECT InvoiceMonth, years, [2] as [Sylvanite, MT], [3] as [Peeples Valley, AZ], [4] as [Medicine Lodge, KS], [5] as [Gasport, NY] , [6] as [Jessie, ND]
                   From (
                        SELECT FORMAT(DATEADD(month,DATEDIFF(MONTH,0,i.InvoiceDate),0), 'dd.MM.yyyy')  as InvoiceMonth, 
		                       c.CustomerID, 
				               i.OrderID, 
				               datepart(year, i.InvoiceDate) as years
                               FROM Sales.Customers c
                                    JOIN Sales.Invoices i on c.CustomerID = i.CustomerID
                                         Where c.CustomerID between 2 and 6 
                        ) as tbl
             PIVOT ( count(OrderID) for CustomerID in ([2], [3], [4], [5], [6])) as PivotDatatable
) as tbl2
order by years asc
 

2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
Select name as CustomerName, AddressLine
       From (
            Select CustomerID, CustomerName as name, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2
                   from Sales.Customers
                        Where CustomerName  like '%Tailspin Toys%'
            ) as People
       UNPIVOT (AddressLine FOR CustomerName IN (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) AS input


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

Select CountryID, name as CountryName, Code
       From (
            Select CountryID, CountryName as name, IsoAlpha3Code, cast(IsoNumericCode as nvarchar(3)) as codes
                   from Application.Countries
            ) as c
       UNPIVOT (Code FOR CountryName IN (IsoAlpha3Code, codes)) AS input


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

Select c.CustomerID, c.CustomerName, StockItemID, UnitPrice, InvoiceDate
       From Sales.Customers c
       Cross apply (
	               Select top 2 CustomerID, CustomerName, StockItemID, UnitPrice, InvoiceDate
                          From Sales.Invoices i
			              JOIN Sales.InvoiceLines l on i.InvoiceID = l.InvoiceID
			                   Where i.CustomerID = c.CustomerID
			                         Order by l.UnitPrice desc
	               ) as tbl