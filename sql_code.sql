SELECT
  e.name,
  e.id AS employee_id,
  i.employee_id AS,
  i.id AS invoice_id
FROM employees e
JOIN invoices i
ON e.id = i.employee_id
;

INNER JOIN = # Return rows that are shared between both tables
LEFT JOIN = # Return # of rows equal to left definition
RIGHT JOIN
OUTER JOIN = # return # rows equal to table_1 rows * table_2 rows
