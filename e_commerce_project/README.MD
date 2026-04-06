# E-Commerce Sales & Customer Analytics (SQL Project)

## Project Overview
This project analyzes an e-commerce dataset using SQL to uncover business insights related to revenue, customer behavior, product performance, and return patterns.

The goal of the project is to simulate the work of a data analyst by answering real-world business questions using SQL queries.

## Tools Used
- SQL (MySQL)
- Data Analysis
- Window Functions
- Common Table Expressions (CTEs)

## Dataset Tables
The project uses the following datasets:

customers – customer information including name and city  
orders – order details including order date, payment method, and order status  
order_items – product level order details including quantity and unit price  
products – product details including category  
returns – information about returned items and refund amount  

## Analysis Performed

### Revenue Analysis
- Monthly revenue trends
- Yearly revenue performance
- Month-over-month revenue growth

### Customer Analysis
- Top spending customers
- Top 5% highest value customers
- Orders per customer
- Cities generating the highest revenue

### Product Performance
- Best selling products by revenue
- Best performing product categories

### Order Analysis
- Average order value
- Most common payment method
- Cancelled order rate

### Return Analysis
- Return rate per product
- Categories with the most returns
- Refund trends over time

### Key KPI Analysis
- Top product in each category
- Month-over-month revenue growth
- Top customers in each city

## Key Business Questions
This analysis answers several important business questions:

- Which months generate the highest revenue?
- Which customers contribute the most to revenue?
- Which product categories perform best?
- What is the return rate of products?
- Which cities generate the highest sales?

## Project Structure

ecommerce-sql-analysis
|
|-- dataset
|   customers.csv
|   products.csv
|   orders.csv
|   order_items.csv
|   returns.csv
|
|-- sql
|   analysis_queries.sql
|
|-- insights
|   business_insights.md
|
|-- README.md