# Customer-Behaviour-Analysis-MSSQL-Server

### Questions

1. What is the total amount each customer spent in the restaurant?
   ```
      SELECT s.customer_id, SUM(m.price) AS total_spent
      FROM dbo.sales s
      INNER JOIN dbo.menu m
      ON s.product_id = m.product_id
      GROUP BY s.customer_id;
```
