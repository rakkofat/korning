# Use this file to import the sales information into the
# the database.

require "pg"
require 'csv'
require 'pry'

system 'psql korning < schema.sql'

def db_connection
  begin
    connection = PG.connect(dbname: "korning")
    yield(connection)
  ensure
    connection.close
  end
end

def extract(key)
  @info.map { |row| row[key] }.uniq
end

def get_id(name, table)
  response = db_connection do |conn|
    conn.exec_params(
      "SELECT t.id FROM #{table} t WHERE t.name = ($1)",
      [name]
    )
  end
  response.first['id'].to_i
end

@info = CSV
  .readlines('sales.csv', headers: true)
  .map(&:to_hash)
  .each { |row|
    name = row['employee'].split[0..1].join(' ')
    email = row['employee'].split[2][1..-2]
    row['employee'] = { name: name, email:  email }
    customer = row['customer_and_account_no'].split[0]
    account_no = row['customer_and_account_no'].split[1][1..-2]
    row['customer_and_account_no'] = { name: customer, account_no: account_no }
  }

db_connection do |conn|
  extract('employee').each do |row|
    name = row[:name]
    email = row[:email]
    conn.exec_params(
      'INSERT INTO
       employees (name, email)
       VALUES ($1, $2)', [name, email]
    )
  end
end

db_connection do |conn|
  extract('customer_and_account_no').each do |row|
    name = row[:name]
    account_no = row[:account_no]
    conn.exec_params(
      'INSERT INTO
       customers (name, account_no)
       VALUES ($1, $2)', [name, account_no]
    )
  end
end

db_connection do |conn|
  extract('product_name').each do |name|
    conn.exec_params(
      'INSERT INTO
       products (name)
       VALUES ($1)', [name]
    )
  end
end

db_connection do |conn|
  extract('invoice_frequency').each do |f|
    conn.exec_params(
      'INSERT INTO
       frequencies (name)
       VALUES ($1)', [f]
    )
  end
end

db_connection do |conn|
 @info.each do |row|
   employee_id = get_id(row['employee'][:name], 'employees')
   customer_id = get_id(row['customer_and_account_no'][:name], 'customers')
   frequency_id = get_id(row['invoice_frequency'], 'frequencies')
   invoice_no = row['invoice_no'].to_i
   sale_date = row['sale_date']
   sale_amount = row['sale_amount'][1..-1].to_f
   units_sold = row['units_sold'].to_i
   conn.exec_params(
    'INSERT INTO invoices
      (employee_id, customer_id, frequency_id, invoice_no,
        sale_date, sale_amount, units_sold)
    VALUES ($1, $2, $3, $4, $5, $6, $7)',
    [employee_id, customer_id, frequency_id, invoice_no,
      sale_date, sale_amount, units_sold]
   )
 end
end
