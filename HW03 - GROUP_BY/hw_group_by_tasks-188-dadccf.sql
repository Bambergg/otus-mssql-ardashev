
/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
Year(i.InvoiceDate) as YearSales,
Month(i.InvoiceDate) as MonthSales,
AVG(l.UnitPrice) AS AVGUnitPrice,
SUM(l.Quantity * l.UnitPrice) as SumInvoices -- Результат странный, очень большие суммы, если где то ошибся - укажите пожалуйста.
FROM [Sales].[Invoices] i
Join [InvoiceLines] l on i.InvoiceID = l.InvoiceID
GROUP BY Year(i.InvoiceDate), Month(i.InvoiceDate)
Order by Year(i.InvoiceDate), Month(i.InvoiceDate)


/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
Year(i.InvoiceDate) as YearSales,
Month(i.InvoiceDate) as MonthSales,
SUM(l.Quantity * l.UnitPrice) as SumInvoices
FROM [Sales].[Invoices] i
Join [Sales].[InvoiceLines] l on i.InvoiceID = l.InvoiceID
GROUP BY Year(i.InvoiceDate), Month(i.InvoiceDate)
Having SUM(l.Quantity * l.UnitPrice) >10000
Order by Year(i.InvoiceDate), Month(i.InvoiceDate)


/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
Year(i.InvoiceDate) as YearSales,
Month(i.InvoiceDate) as MonthSales,
s.StockItemName,
SUM(l.Quantity * l.UnitPrice) as SumInvoices,
Count(l.StockItemID) as QuantityOfGoods -- Не смог понять как получить дату первой продажи, нужна помощь)
FROM [Sales].[Invoices] i
Join [Sales].[InvoiceLines] l on i.InvoiceID = l.InvoiceID
Join [Warehouse].[StockItems] s on s.StockItemID = l.StockItemID
GROUP BY Year(i.InvoiceDate), Month(i.InvoiceDate), s.StockItemName


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
