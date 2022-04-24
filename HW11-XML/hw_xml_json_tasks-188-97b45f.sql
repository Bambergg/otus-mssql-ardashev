/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/
DECLARE @xmlDocument  xml

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'C:\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
as data 

SELECT @xmlDocument as [@xmlDocument]

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

SELECT @docHandle as docHandle

SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	 [StockItemName] nvarchar(100) '@Name',
	 [SupplierID] int 'SupplierID',
	 [UnitPackageID] int 'Package/UnitPackageID',
	 [OuterPackageID] int 'Package/OuterPackageID',
	 [QuantityPerOuter] int 'Package/QuantityPerOuter',
	 [TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
	 [LeadTimeDays] int 'LeadTimeDays',
	 [IsChillerStock] bit 'IsChillerStock',
	 [TaxRate] decimal(18,3) 'TaxRate',
	 [UnitPrice] decimal(18,2) 'UnitPrice'
	 )


Create table Warehouse.StockItemsCopy(
             [StockItemName] nvarchar(100),
	         [SupplierID] int,
	         [UnitPackageID] int,
	         [OuterPackageID] int,
	         [QuantityPerOuter] int,
             [TypicalWeightPerUnit] decimal(18,3),
			 [LeadTimeDays] int,
			 [IsChillerStock] bit,
			 [TaxRate] decimal(18,3),
			 [UnitPrice] decimal(18,2)
							         )

Insert into Warehouse.StockItemsCopy
--________________________________________________________________________________________________________

Merge Warehouse.StockItems as StockItems
Using Warehouse.StockItemsCopy as ItemsCopy
ON (StockItems.StockItemName = ItemsCopy.StockItemName)
When MATCHED and StockItems.StockItemName = ItemsCopy.StockItemName 
             THEN Update 
			            SET SupplierID = ItemsCopy.SupplierID, 
			            UnitPackageID = ItemsCopy.UnitPackageID,
					    OuterPackageID = ItemsCopy.OuterPackageID,
						QuantityPerOuter = ItemsCopy.QuantityPerOuter,
						TypicalWeightPerUnit = ItemsCopy.TypicalWeightPerUnit,
						LeadTimeDays = ItemsCopy.LeadTimeDays,
						IsChillerStock = ItemsCopy.IsChillerStock,
						TaxRate = ItemsCopy.TaxRate,
						UnitPrice = ItemsCopy.UnitPrice
When NOT MATCHED THEN
                        INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
				        Values (ItemsCopy.StockItemName, ItemsCopy.SupplierID, ItemsCopy.UnitPackageID, ItemsCopy.OuterPackageID, ItemsCopy.QuantityPerOuter, ItemsCopy.TypicalWeightPerUnit, ItemsCopy.LeadTimeDays, ItemsCopy.IsChillerStock, ItemsCopy.TaxRate, ItemsCopy.UnitPrice, '1')   
Output $action, inserted.*;


 
/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/
select 
     [StockItemName] as [@Item],
	 [SupplierID] as [SupplierID],
	 [UnitPackageID] as [Package/UnitPackageID],
	 [OuterPackageID] as [Package/OuterPackageID],
	 [QuantityPerOuter] as [Package/QuantityPerOuter],
	 [TypicalWeightPerUnit] as [Package/TypicalWeightPerUnit],
	 [LeadTimeDays] as [LeadTimeDays],
	 [IsChillerStock] as [IsChillerStock],
	 [TaxRate] as [TaxRate],
	 [UnitPrice] as [UnitPrice]
from Warehouse.StockItems
for xml path('Item'), root ('StockItems')


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select 
      StockItemID,
	  StockItemName,
	  JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
	  JSON_VALUE(CustomFields, '$.Tags[0]') as Tags
from Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

select 
      StockItemID,
	  StockItemName,
	  JSON_Query(CustomFields, '$.Tags') as Tags
from Warehouse.StockItems
CROSS APPLY OPENJSON(CustomFields, '$.Tags') sites
WHERE sites.value = 'Vintage'