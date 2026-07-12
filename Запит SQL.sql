USE clothing_network_analytics
--Тест 1: Перевірка лідерства міст (Виторг без урахування знижок)
SELECT s.city, SUM(sa.quantity * p.retail_price) as gross_revenue, COUNT(sa.sale_id) as total_orders
FROM sales sa
JOIN stores s ON sa.store_id = s.store_id
JOIN products p ON sa.product_id = p.product_id
GROUP BY s.city
ORDER BY gross_revenue DESC;

-- Тест 2: Перевірка категорій-лідерів
SELECT p.main_category, SUM(sa.quantity * p.retail_price) as gross_revenue, SUM(sa.quantity) as items_sold
FROM sales sa
JOIN products p ON sa.product_id = p.product_id
GROUP BY p.main_category
ORDER BY gross_revenue DESC;

-- Загальний огляд мережі (Верхньоlevel-метрики)
SELECT 
    COUNT(DISTINCT sale_id) as total_orders,
    SUM(quantity) as total_items_sold,
    -- Брутто-виторг (без знижок)
    SUM(quantity * retail_price) as gross_revenue,
    -- Скільки грошей ми втратили на знижках
    SUM(quantity * retail_price * discount_pct) as total_discounts_given,
    -- Фінальний виторг (нетто)
    SUM(quantity * retail_price * (1 - discount_pct)) as net_revenue
FROM sales sa
JOIN products p ON sa.product_id = p.product_id;

-- Аналіз лідерства міст (Порівняння локацій)
SELECT 
    s.city,
    COUNT(DISTINCT sa.sale_id) as total_orders,
    -- Фактичний виторг
    ROUND(SUM(sa.quantity * p.retail_price * (1 - sa.discount_pct)), 2) as net_revenue,
    -- Чистий прибуток (Маржа в абсолютних грошах)
    ROUND(SUM(sa.quantity * (p.retail_price * (1 - sa.discount_pct) - p.purchase_price)), 2) as total_profit,
    -- Середній чек (Виторг / Кількість замовлень)
    ROUND(SUM(sa.quantity * p.retail_price * (1 - sa.discount_pct)) / COUNT(DISTINCT sa.sale_id), 2) as avg_order_value
FROM sales sa
JOIN stores s ON sa.store_id = s.store_id
JOIN products p ON sa.product_id = p.product_id
GROUP BY s.city
ORDER BY net_revenue DESC;

-- Категорійний аналіз (Пошук локомотивів)
SELECT 
    p.main_category,
    SUM(sa.quantity) as items_sold,
    ROUND(SUM(sa.quantity * p.retail_price * (1 - sa.discount_pct)), 2) as net_revenue,
    ROUND(SUM(sa.quantity * (p.retail_price * (1 - sa.discount_pct) - p.purchase_price)), 2) as total_profit,
    -- Маржинальність у % (Прибуток / Виторг * 100)
    ROUND((SUM(sa.quantity * (p.retail_price * (1 - sa.discount_pct) - p.purchase_price)) / SUM(sa.quantity * p.retail_price * (1 - sa.discount_pct))) * 100, 2) as margin_pct
FROM sales sa
JOIN products p ON sa.product_id = p.product_id
GROUP BY p.main_category
ORDER BY total_profit DESC;

-- Вплив знижок на прибутковість
SELECT 
    CONCAT(sa.discount_pct * 100, '%') as discount_level,
    COUNT(sa.sale_id) as total_sales,
    SUM(sa.quantity) as items_sold,
    ROUND(SUM(sa.quantity * p.retail_price * (1 - sa.discount_pct)), 2) as net_revenue,
    -- Середня маржа на один товар при такій знижці
    ROUND(AVG(p.retail_price * (1 - sa.discount_pct) - p.purchase_price), 2) as avg_profit_per_item
FROM sales sa
JOIN products p ON sa.product_id = p.product_id
GROUP BY sa.discount_pct
ORDER BY sa.discount_pct ASC;

-- Сворення таблиці для візуалізації
SELECT 
    sa.sale_id AS `ID Замовлення`,
    sa.date AS `Дата`,
    -- Створюємо додаткові текстові поля для зручної фільтрації за періодами в Tableau
    YEAR(sa.date) AS `Рік`,
    MONTHNAME(sa.date) AS `Місяць`,
    
    -- Дані про магазин
    s.city AS `Місто`,
    s.manager AS `Менеджер магазину`,
    
    -- Дані про товар
    p.product_id AS `ID Товару`,
    p.product_name AS `Назва товару`,
    p.main_category AS `Основна категорія`,
    p.sub_category AS `Підкатегорія`,
    
    -- Кількісні показники з транзакції
    sa.quantity AS `Кількість (шт)`,
    sa.discount_pct AS `Відсоток знижки`,
    
    -- Фінансові метрики на одиницю товару
    p.purchase_price AS `Собівартість за од.`,
    p.retail_price AS `Базова ціна за од.`,
    ROUND(p.retail_price * (1 - sa.discount_pct), 2) AS `Ціна зі знижкою за од.`,
    
    -- Загальні фінансові метрики для всього замовлення (Quantity * Price)
    ROUND(sa.quantity * p.retail_price, 2) AS `Брутто Виторг`,
    ROUND(sa.quantity * p.retail_price * sa.discount_pct, 2) AS `Сума знижки`,
    ROUND(sa.quantity * p.retail_price * (1 - sa.discount_pct), 2) AS `Нетто Виторг (Каса)`,
    ROUND(sa.quantity * p.purchase_price, 2) AS `Загальна Собівартість закупу`,
    -- Чистий прибуток з усього замовлення
    ROUND((sa.quantity * p.retail_price * (1 - sa.discount_pct)) - (sa.quantity * p.purchase_price), 2) AS `Чистий прибуток (Маржа)`

FROM sales sa
JOIN stores s ON sa.store_id = s.store_id
JOIN products p ON sa.product_id = p.product_id
ORDER BY sa.date ASC;