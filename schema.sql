-- Schema for a small online office-supplies store (PostgreSQL)

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id  INTEGER PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    city         VARCHAR(50)  NOT NULL,
    signup_date  DATE         NOT NULL
);

CREATE TABLE products (
    product_id  INTEGER PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    category    VARCHAR(50)   NOT NULL,
    price       NUMERIC(10,2) NOT NULL
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER     NOT NULL REFERENCES customers(customer_id),
    order_date   DATE        NOT NULL,
    status       VARCHAR(20) NOT NULL CHECK (status IN ('delivered', 'cancelled', 'pending'))
);

CREATE TABLE order_items (
    order_id    INTEGER       NOT NULL REFERENCES orders(order_id),
    product_id  INTEGER       NOT NULL REFERENCES products(product_id),
    quantity    INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
