# 🕶️ Sunglass Store – dbt Analytics Project

This repository contains the dbt (data build tool) project for the Sunglass Store, an e-commerce business focused on eyewear. The project transforms raw data into clean, reliable, and analysis-ready models following the medallion architecture (Bronze → Silver → Gold).    

---


## 📁 Repository Structure

| Path                          | Description                                                                 |
|-------------------------------|-----------------------------------------------------------------------------|
| `analyses/`                   | Stores ad hoc analysis queries (optional).                                  |
| `macros/`                     | Contains reusable Jinja macros for transformations.                         |
| `models/source.yml`           | Bronze layer: Defines raw source tables (used with `source()` function).    |
| `models/schema.yml`           | Contains schema-level tests for models and columns.                         |
| `models/cleaned_tables/`      | Silver layer: Cleans and standardizes raw source tables.                    |
| `models/dim/`                 | Gold layer: Dimension tables like `dim_users`, `dim_products`, `dim_dates`. |
| `models/fact/`                | Gold layer: Fact tables such as `fct_orders` and `fct_interactions`.        |
| `seeds/`                      | Holds static `.csv` seed files                                              |
| `snapshots/`                  | Used for tracking slowly changing dimensions over time.                     |
| `tests/`                      | Custom schema tests.                                                        |
| `.gitignore`                  | Specifies files and folders Git should ignore.                              |
| `README.md`                   | This file – provides an overview of the project.                            |
| `dbt_project.yml`             | Main config file for dbt – defines structure and materialization settings.  |


## 🧱 Layered Architecture
### 🥉 Bronze Layer – Raw Data Sources

The **Bronze Layer** represents the **starting point of our data pipeline**. It contains **unprocessed, raw data** directly sourced from the original data system. In this project, the raw data resides in **AWS Athena**, and it is **connected through dbt using the `AwsDataCatalog`**. These source tables are **registered using the `sources` feature in the `source.yml` file located in the `models/` folder**. This setup provides traceability, supports data lineage, and enables easy referencing for transformations in downstream layers.


#### ✅ Purpose
- Serves as the **raw input layer** for the dbt project.
- Provides a single, traceable location to define where the raw data lives.
- Feeds into the **Silver Layer**, where data cleaning and transformation occur.

#### 📄 Defined in
- 📁 `models/source.yml`

#### 🧩 Raw Tables Included

| Table Name          | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `orders`            | Customer purchase data, including `payment_type`, `purchase_date`, and `order_id`. |
| `interactions`      | User activity log: actions like "viewed", "added to cart", etc.             |
| `products`          | Product catalog including brand, lens color, price, and listing dates.      |
| `users`             | Customer profile data such as name, gender, email, country, etc.            |
| `interaction_types` | Defines what each interaction means (e.g., viewed, purchased).              |

#### 🛠 Source.yml Configuration

```yaml
version: 2

sources:
  - name: raw_data
    database: AwsDataCatalog
    schema: sunglass_store
    tables:

      - name: orders
        identifier: orders

      - name: interactions
        identifier: interactions

      - name: products
        identifier: products

      - name: users
        identifier: users

      - name: interaction_types
        identifier: interaction_types
```
### 🥈 Silver Layer – Cleaned and Standardized Data

The **Silver Layer** is where the raw data from the Bronze Layer is **cleaned, formatted, and standardized** to make it ready for analytical use. It ensures data consistency, removes formatting issues, and enriches the raw data for downstream modeling. These models are created using **dbt SQL files** in the `models/cleaned_tables/` folder. Each model uses the `ref()` function to reference the corresponding raw table from the Bronze Layer (as defined in `source.yml`).

#### ✅ Purpose
- Ensures that raw data is **reliable, clean, and analysis-ready**.
- Applies business logic like data type conversions, string cleanup, and column formatting.
- Serves as a **bridge between raw and analytical models** (Gold Layer).

#### 📄 Defined in
- 📁 `models/cleaned_tables/`

#### ⚙️ Key Transformations
Each table in the Silver Layer applies specific data cleaning techniques, such as:
- Removing special characters using **regex**.
- Converting timestamp strings to **standardized date formats**.
- Standardizing **text casing** (e.g., capitalizing names, lowercasing emails).
- Trimming unwanted whitespace or characters.

#### 🧹 Cleaned Tables Overview

| Table Name             | Description                                                                                  |
|------------------------|----------------------------------------------------------------------------------------------|
| `orders_cleaned`       | Cleans `payment_type`, formats `purchase_date`, and keeps only necessary order attributes.   |
| `interactions_cleaned` | Standardizes `interaction_date` and formats interaction data.                                |
| `products_cleaned`     | Cleans `brand` and `lens_color`, converts `list_date` and `discontinued_date` to date.       |
| `users_cleaned`        | Formats names, cleans platform strings, lowercases emails, and converts join dates.          |
| `interaction_types_cleaned` | Cleans `interaction_type` strings for consistency.                                      |

#### 🔁 dbt Model Reference

```sql
-- orders_cleaned.sql
with orders_cleaned as (
    select * from {{ source('raw_data', 'orders') }}
)
select 
    user_id,
    item_id,
    date(purchase_date) as purchase_date,
    order_id,
    trim(regexp_replace(payment_type,'[.,/_-]', ' ')) as payment_type
from orders_cleaned

-- users_cleaned.sql
with users_cleaned as (
                        select * from {{source('raw_data','users')}}
)
select 
		user_id,
		upper(substring(first_name,1 ,1))|| lower(substring(first_name from 2)) as first_name,
		upper(substring(last_name,1 ,1))|| lower(substring(last_name from 2)) as last_name,
		lower(email) as email,
		age,
		upper(substring(gender from 1 for 1))as gender,
		post_code,
		upper(substring(country,1 ,1))|| lower(substring(country from 2)) as country,
		cast(join_date as date) as join_date,
		trim(REGEXP_REPLACE(from_platform, '[, . \ - _ ?]', ' ')) as from_platform
from users_cleaned;

-- product_cleaned.sql
with products_cleaned as (
                            select * from {{source('raw_data','products')}}
)
select 
		item_id,
		trim(regexp_replace(brand,'[.,_-]',' ')) as brand,
		product_name,
		eye_size,
		trim(regexp_replace(lens_color,'[.,_-]',' ')) as lens_color,
		price,
		polarized_glasses,
		prescribed_glasses,
		is_active,
		cast(list_date as date) as list_date,
		cast(discontinued_date as date) as discontinued_date
from products_cleaned;

--interactions_cleaned.sql
with interactions_cleaned as (
                                select * from {{source('raw_data','interactions')}}
)
select 
		user_id,
		item_id,
		cast(interaction_date as date) as interaction_date,
		interaction_id
from interactions_cleaned;

-- interaction_types_cleaned.sql
with interaction_types_cleaned as (
                                    select * from {{source('raw_data','interaction_types')}}
)
select 
		id,
		trim(regexp_replace(interaction_type,'[,._/]',' ')) as interaction_type
from interaction_types_cleaned;
```

### 🥇 Gold Layer – Analytical Models (Fact and Dimension Tables)

The **Gold Layer** is typically the trusted foundation for business analytics, containing analytical models that are ready for reporting, dashboards, and decision-making. These models are built using cleaned and validated data from the Silver Layer. While often referred to as the final step in the dbt pipeline, the Gold Layer can also serve as the basis for further domain-specific modeling

These models are materialized as **tables** to support faster query performance.

📂 Located in:
- `models/dim/` → Dimension tables
- `models/fact/` → Fact tables


#### ✅ Purpose of the Gold Layer

- Delivers **structured, analysis-ready tables**.
- Follows the **star schema design** with **fact** and **dimension** tables.
- Used directly in **dashboards and analytics tools** (e.g., Power BI, Tableau).
- Helps build consistent, reliable KPIs and business logic.

#### 🔁 Gold Layer as a Foundation for More Models

Although often referred to as the "final layer", the **Gold Layer** can also serve as a strong foundation for further modeling, including:

- **Aggregated models**:  
  _Examples_: Daily sales summaries, product popularity rankings

- **KPI models**:  
  _Examples_: Conversion rates, most-engaged users

- **Business logic models**:  
  _Examples_: Segmenting customers based on behavior or activity levels

- **Domain-specific data marts**:  
  _Examples_: Marketing campaign performance, customer service efficiency, product optimization analytics

The Gold Layer empowers downstream use cases that are **tailored to the Sunglass Store’s unique business needs**.


#### 📊 Dimension Tables (`models/dim/`)

Dimension tables provide descriptive information and context for facts. They are used to **filter, group, and segment data**.

| Table Name               | Description                                                                 |
|--------------------------|-----------------------------------------------------------------------------|
| `dim_users`              | Contains cleaned user profiles with demographic and platform details.       |
| `dim_products`           | Describes product features including brand, price, availability, etc.       |
| `dim_interaction_types`  | Lookup table for interaction codes like viewed, purchased, etc.             |
| `dim_dates`              | **Custom-built date table** with full calendar context (weekday, month, etc.). |

#### 🗓️ About `dim_dates`

The `dim_dates` table was **additionally created** to serve as a **central date reference table**. It covers a continuous date range from 2018 to 2026 and includes:

- Day, month, year
- Day of week / day type (Weekday or Weekend)
- Weekday names
- Month names
- Quarter
- Day of year

🔗 It's used to **join** all tables with a date field such as:
- `join_date` from `dim_users`
- `list_date` from `dim_products`
- `interaction_date` from `fct_interactions`
- `purchase_date` from `fct_orders`

> 📌 Purpose: Ensures **consistent date logic and filtering** across all fact tables and dimensions.


#### 📈 Fact Tables (`models/fact/`)

Fact tables record **business events** and reference dimension tables via foreign keys.

| Table Name         | Description                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| `fct_orders`       | Contains purchase-level data: user, item, date, and payment type.           |
| `fct_interactions` | Logs user-product interactions like "viewed", "added to cart", etc.         |

#### ⚙️ Incremental Model Configuration

To improve performance and manage large datasets efficiently, **incremental models** were used in this layer.

#### 🧠 What Are Incremental Models?

Incremental models in dbt are designed to **append only new or updated data** instead of reprocessing the entire dataset every time you run `dbt run`.

#### ✅ Why It’s Important

- **Performance Boost**: Only new rows are processed, which makes builds faster and reduces compute costs—especially helpful with large datasets in cloud environments like AWS Athena.
- **Efficiency**: Avoids redundant data transformation and storage.
- **Scalability**: Suitable for growing datasets and frequent refreshes.
- **Data Consistency**: With `unique_key` and `on_schema_change`, dbt ensures only valid, non-duplicate data is inserted.

#### 🔁 dbt Model Reference

```sql
-- dim_users.sql
{{ 
    config(
            materialized = 'incremental',
            on_schema_change = 'fail'
    )
}}
select * from {{ ref('users_cleaned') }}
{% if is_incremental() %}
    where user_id > (select max(user_id) from {{ this }})
{% endif %}


--dim_products.sql
{{
    config(
        materialized = 'incremental',
        on_schema_change = 'fail'
    )
}}
select * from {{ ref('products_cleaned') }}
{% if is_incremental() %}
    where item_id > (select max(item_id) from {{this}})
{% endif %}


--dim_interaction_types.sql
select * from {{ref('interaction_types_cleaned')}}


--dim_dates.sql
{{ config(
    materialized = 'table'
) }}

with date_range as (

    select 
        sequence(
            date '2018-01-01',
            date '2026-12-31',
            interval '1' day
        ) as date_array

),

flattened as (

    select 
        cast(date_day as date) as date_actual
    from date_range,
    unnest(date_array) as t(date_day)

)

select 
    date_actual,
    extract(year from date_actual) as year,
    extract(month from date_actual) as month,
    extract(day from date_actual) as day,
    extract(quarter from date_actual) as quarter,
    extract(dow from date_actual) as day_of_week,       
    extract(doy from date_actual) as day_of_year,
    format_datetime(date_actual, 'MMMM') as month_name,
    format_datetime(date_actual, 'EEEE') as weekday_name,
    case when extract(dow from date_actual) in (1, 7) then 'Weekend' else 'Weekday' end as day_type

from flattened



--fct_interactions.sql
{{
    config(
        materialized = 'incremental',
        on_schema_change = 'fail'
    )
}}
select * from {{ref('interactions_cleaned')}}
{% if is_incremental() %}
    where interaction_id > (select max(interaction_id) from {{this}}) 
{% endif %}


--fct_orders
{{
    config(
        materialized = 'incremental',
        on_schema_change = 'fail'
    )
}}
select * from {{ref('orders_cleaned')}}
{% if is_incremental() %}
    where order_id > (select max(order_id) from {{this}})
{% endif %}
```

---
### 🧪 Data Testing – `schema.yml`

The `schema.yml` file in the dbt project defines a set of **data quality tests** to validate the integrity, consistency, and accuracy of the data across all layers. These tests help catch issues early and ensure that the transformed data meets business expectations.

#### ✅ Purpose of Tests
- Validate **uniqueness** and **non-null** constraints on key fields.
- Ensure **referential integrity** between dimension and fact tables.
- Confirm that categorical fields contain only **expected values**.
- Improve **trust** and **reliability** of the data pipeline.

#### 📂 Location
- File: `models/schema.yml`


#### 🧩 Test Types Used

| Test Type           | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `not_null`          | Ensures the column has no missing values.                                   |
| `unique`            | Verifies that the column contains only unique values (e.g., IDs).           |
| `accepted_values`   | Confirms that a column’s values fall within a predefined list (e.g., gender).|
| `relationships`     | Validates foreign key relationships between models (e.g., dates, users).    |


#### 🧪 Test Definitions

```yaml
version: 2

models:

  - name: dim_dates
    columns:

      - name: date_actual
        tests:
          - unique
          - not_null

      - name: year
        tests:
          - not_null

      - name: month
        tests:
          - not_null
      
      - name: day
        tests:
          - not_null

      - name: quarter
        tests:
          - not_null

      - name: day_of_week
        tests:
          - not_null

      - name: day_of_year
        tests:
          - not_null

      - name: month_name
        tests:
          - not_null
          - accepted_values:
              values: ['January', 'February','March','April','May','June','July','August','September','October','November','December']

      - name: weekday_name
        tests:
          - not_null
          - accepted_values:
              values: ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']

      - name: day_type
        tests:
          - not_null
          - accepted_values:
              values: ['Weekday','Weekend']

  - name: dim_interaction_types
    columns:

      - name: id 
        tests:
          - not_null
          - unique

      - name: interaction_type 
        tests:
          - not_null
          
  - name: dim_products
    columns:

      - name: item_id
        tests:
          - unique
          - not_null
      
      - name: brand
        tests:
          - not_null

      - name: product_name
        tests:
          - not_null

      - name: eye_size
        tests:
          - not_null

      - name: lens_color
        tests:
          - not_null

      - name: price
        tests:
          - not_null

      - name: polarized_glasses
        tests:
          - not_null
          - accepted_values:
              values: ['Yes','No'] 

      - name: prescribed_glasses
        tests:
          - not_null
          - accepted_values:
              values: ['Yes','No']                
      - name: is_active
        tests:
          - not_null

      - name: list_date
        tests:
          - not_null
          - relationships:
              to: ref('dim_dates')
              field: date_actual
      
  - name: dim_users
    columns:

      - name: user_id
        tests:
          - unique
          - not_null
      
      - name: first_name
        tests:
          - not_null

      - name: last_name
        tests:
          - not_null

      - name: email
        tests:
          - not_null  

      - name: age
        tests:
          - not_null

      - name: gender
        tests:
          - not_null
          - accepted_values:
              values: ['M','F']
      
      - name: post_code
        tests:
          - not_null

      - name: country
        tests:
          - not_null

      - name: join_date
        tests:
          - not_null
          - relationships:
              to: ref('dim_dates')
              field: date_actual

      - name: from_platform
        tests:
          - not_null

  - name: fct_interactions
    columns:

      - name: user_id
        tests:
          - not_null
          - relationships:
              to: ref('dim_users')          
              field: user_id

      - name: item_id
        tests:
          - not_null
          - relationships:
              to: ref('dim_products')
              field: item_id

      - name: interaction_date
        tests:
          - not_null
          - relationships:
              to: ref('dim_dates')       
              field: date_actual

      - name: interaction_id
        tests:
          - not_null
          - relationships:
              to: ref('dim_interaction_types')         
              field: id

  - name: fct_orders
    columns:

      - name: user_id
        tests:
          - not_null
          - relationships:
              to: ref('dim_users')    
              field: user_id

      - name: item_id
        tests:
          - not_null
          - relationships:
              to: ref('dim_products')
              field: item_id

      - name: purchase_date
        tests:
          - not_null
          - relationships:
              to: ref('dim_dates')
              field: date_actual

      - name: order_id
        tests:
          - unique
          - not_null

      - name: payment_type
        tests:
          - not_null
```
