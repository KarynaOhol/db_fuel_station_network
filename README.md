# Fuel Station Network Database Model Documentation

## 1. Business Description

The Fuel Station Network database system is designed to manage a network of fuel stations, including their inventory, sales, staff, and supply chain operations. This system supports the following business functions:

### Core Business Functions:

- **Station Management**: Track details of individual fuel stations including location, operating hours, and ownership.
- **Fuel Inventory Management**: Monitor fuel types, quantities, and pricing across all stations.
- **Sales Processing**: Record and analyze fuel sales transactions, including customer information when available.
- **Supply Chain Management**: Track fuel deliveries, suppliers, and replenishment schedules.
- **Staff Management**: Maintain employee records and associate them with specific stations and sales.
- **Customer Management**: Store information about registered customers for loyalty programs and analysis.

### Business Rules:

1. Each fuel station offers one or more types of fuel
2. Fuel prices can vary by station and may include regular and discounted rates
3. Fuel sales must be processed by an employee and recorded with timestamp, quantity, and payment details
4. Fuel deliveries are received from suppliers and update station inventory levels
5. Employees are assigned to specific stations
6. Customers may be registered in the system or remain anonymous for one-time purchases

###  Entities and Attributes

Based on the business requirements, I identified the following primary entities:

1. **STATION**: Represents individual fuel stations
   - Attributes: station_id, station_name, address, city, state_province, postal_code, country, phone, latitude, longitude, opening_time, closing_time, is_24hr, owner_id, created_at, updated_at

2. **FUEL_TYPE**: Represents different types of fuel offered
   - Attributes: fuel_type_id, fuel_name, description, is_active, created_at

3. **STATION_FUEL**: Junction entity connecting stations and fuel types
   - Attributes: station_fuel_id, station_id, fuel_type_id, regular_price, discounted_price, current_quantity, capacity, is_available, last_updated

4. **CUSTOMER**: Represents registered customers
   - Attributes: customer_id, first_name, last_name, email, phone, address, city, state_province, postal_code, country, registration_date, has_loyalty_card, is_active

5. **EMPLOYEE**: Represents staff members at stations
   - Attributes: employee_id, first_name, last_name, email, phone, address, city, state_province, postal_code, country, hire_date, termination_date, station_id, position, hourly_rate, is_active

6. **FUEL_SALE**: Records individual fuel sale transactions
   - Attributes: sale_id, station_id, fuel_type_id, customer_id, employee_id, sale_datetime, quantity_sold, unit_price, total_amount, payment_method, payment_reference, loyalty_discount_applied

7. **SUPPLIER**: Contains information about fuel suppliers
   - Attributes: supplier_id, supplier_name, contact_person, email, phone, address, city, state_province, postal_code, country, is_active, created_at

8. **FUEL_DELIVERY**: Tracks fuel deliveries from suppliers
   - Attributes: delivery_id, station_id, supplier_id, fuel_type_id, delivery_date, quantity, unit_price, total_cost, invoice_number, is_received, received_by, received_at, notes

**For each entity defined Keys and Constraints:**

1. **Primary Keys**: Unique identifiers for each record
2. **Foreign Keys**: References to other entities to maintain referential integrity
3. **Unique Constraints**: For attributes that must be unique (e.g., email addresses)
4. **Not Null Constraints**: For required attributes
5. **Default Values**: For attributes with standard values (e.g., is_active = TRUE)

** For each attribute specified appropriate data types:**
- Integer types for IDs and numeric values
- Varchar for text with specific length limits
- Decimal for monetary values and quantities
- Date/Datetime for timestamps
- Boolean for yes/no flags
- 
### Defined Relationships Between Entities

I identified the following relationships:

1. **STATION to STATION_FUEL**: One-to-many
   - A station offers multiple fuel types
   - Each station-fuel combination belongs to exactly one station

2. **FUEL_TYPE to STATION_FUEL**: One-to-many
   - A fuel type can be available at multiple stations
   - Each station-fuel combination refers to exactly one fuel type

3. **STATION to EMPLOYEE**: One-to-many
   - A station employs multiple staff members
   - Each employee works at exactly one station

4. **STATION to FUEL_SALE**: One-to-many
   - A station records multiple fuel sales
   - Each sale occurs at exactly one station

5. **FUEL_TYPE to FUEL_SALE**: One-to-many
   - A fuel type can be involved in multiple sales
   - Each sale involves exactly one fuel type

6. **CUSTOMER to FUEL_SALE**: One-to-many (optional)
   - A customer can make multiple fuel purchases
   - Each sale is associated with at most one customer (some sales may be anonymous)

7. **EMPLOYEE to FUEL_SALE**: One-to-many
   - An employee processes multiple fuel sales
   - Each sale is processed by exactly one employee

8. **STATION to FUEL_DELIVERY**: One-to-many
   - A station receives multiple fuel deliveries
   - Each delivery is received by exactly one station

9. **SUPPLIER to FUEL_DELIVERY**: One-to-many
   - A supplier provides multiple fuel deliveries
   - Each delivery comes from exactly one supplier

10. **FUEL_TYPE to FUEL_DELIVERY**: One-to-many
    - A fuel type can be included in multiple deliveries
    - Each delivery involves exactly one fuel type


## 3. Benefits of This Model

This fuel station network database model provides several advantages:

1. **Data Integrity**: Normalized structure prevents update anomalies and ensures data consistency.
2. **Scalability**: Can accommodate growth in stations, fuel types, customers, and transactions.
3. **Analytical Capabilities**: Supports comprehensive reporting on sales, inventory, and operational metrics.
4. **Operational Efficiency**: Facilitates day-to-day station operations and supply chain management.
5. **Security**: Clearly defined entities make it easier to implement role-based access controls.

## 4. Potential Future Extensions

The model can be extended to include:

1. **Loyalty Program Management**: Track customer points, rewards, and program tiers.
2. **Maintenance Records**: Schedule and track station equipment maintenance.
3. **Non-Fuel Products**: Add convenience store items and services.
4. **Dynamic Pricing**: Implement time-based pricing rules and competitive analysis.
5. **Electric Charging Stations**: Accommodate emerging fuel technologies.

## 5. Implemented Constraints and Data Population

### 5.1 CHECK Constraints

The following CHECK constraints were implemented to enforce business rules:

1. **chk_valid_delivery_date**: Ensures all fuel deliveries have a delivery date after January 1, 2024.

2. **chk_positive_quantity_sold**: Ensures fuel quantity sold is always positive.

3. **chk_positive_capacity**: Ensures fuel storage capacity is always greater than zero.

4. **chk_minimum_hourly_rate**: Enforces a minimum hourly wage of $15.00 for employees.

5. **chk_valid_payment_method**: Restricts payment methods to a predefined set of values.

6. **chk_valid_business_hours**: Ensures station closing time is after opening time unless it's a 24-hour station.

7. **chk_valid_employment_period**: Ensures termination date is after hire date for employees who have left.


### 5.2 Computed Columns

Several computed columns were implemented to provide derived data:

1. **full_address** in STATION table: Concatenates address components into a single field.
2. **full_name** in CUSTOMER table: Combines first and last name.
3. **available_percentage** in STATION_FUEL table: Calculates the percentage of fuel capacity currently available.

### 5.3 Data Population

The database was populated with sample data using rerunnable scripts that:

1. Create at least 6 records in each table (total of 36+ rows)
2. Span the last 3 months of operations
3. Respect all defined constraints
4. Use appropriate data distribution techniques

Key features of the data insertion scripts:

1. **Rerunnable Design**:
   - Uses ON CONFLICT clauses to prevent duplicate entries
   - Doesn't hardcode surrogate key values
   - Uses temporary sequences and tables for ID generation and relationship management

2. **Data Volume**:
   - 8+ stations
   - 8+ fuel types
   - 8+ suppliers
   - 10+ customers
   - 12+ employees
   - 18+ fuel deliveries
   - 40+ fuel sales

3. **Relationship Integrity**:
   - Maintains referential integrity across all tables
   - Uses appropriate customer and employee distribution techniques
   - Ensures realistic relationships between entities

   
## 6. Functions and view data manipulation

## Functions

### 1. `fuel_net.update_table_column`

**Purpose:**  
Provides a secure, flexible way to update any column in any table using a dynamic SQL approach.

**Business Logic:**
- Validates table and column existence before performing updates
- Prevents SQL injection through parameterized queries
- Returns success/failure status for better error handling
- Supports updates across any table in the database with consistent interface

**Use Cases:**
- Update station information (address, phone, operating hours)
- Modify customer details (contact information, loyalty status)
- Adjust employee data (position, rate, contact details)

### 2. `fuel_net.add_fuel_sale_transaction`

**Purpose:**  
Manages the complete fuel sale transaction process using natural keys instead of surrogate keys.

**Business Logic:**
- Processes sales using business-friendly identifiers (names, emails) instead of IDs
- Performs comprehensive validation checks:
  - Verifies station exists
  - Confirms fuel type availability at the station
  - Checks sufficient fuel quantity
  - Validates employee credentials
  - Optionally links to customer record
- Handles the complete transaction in a single atomic operation:
  - Records the sale details
  - Updates inventory levels
  - Calculates total amount
- Provides detailed success/failure information with meaningful error messages

## View

### `fuel_net.station_quarterly_performance`

**Purpose:**  
Provides consolidated quarterly performance analytics across all stations and fuel types.

**Business Logic:**
- Automatically identifies and uses the most recent quarter with data
- Combines sales and delivery data to calculate true profitability
- Excludes technical fields (surrogate keys) to focus on business metrics
- Calculates derived KPIs:
  - Gross profit
  - Profit margins
  - Sales velocity
  - Customer metrics

**Business Value:**
- Enables quick identification of top and underperforming stations
- Provides insights on customer engagement and spending patterns
- Shows operational efficiency through sales velocity metrics
- Supports data-driven inventory and pricing decisions

## 7. Database Role Management

### `fuel_manager` Role

**Purpose:**  
Provides secure, limited access for station managers to view operational data without modification rights.

**Advantages:**
1. **Enhanced Security:**
   - Restricts data access based on job function
   - Prevents accidental data corruption
   - Limits concurrent connections to manage server load

2. **Operational Benefits:**
   - Gives management visibility into performance metrics
   - Enables data-driven decision making at management level
   - Provides accountability through user identification

3. **Compliance Advantages:**
   - Supports principle of least privilege for data security
   - Creates audit trail by identifying users
   - Helps meet regulatory requirements for data access control

4. **Administrative Efficiency:**
   - Simplifies permission management through role-based access
   - Reduces need for individual user permission grants
   - Streamlines onboarding of new managers

The role expires automatically after one year, ensuring periodic security review.
