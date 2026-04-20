import sys
import logging
import pymysql
import json
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
DB_USER = os.environ['DB_USER']
DB_PASS = os.environ['DB_PASS']
DB_HOST = os.environ['RDS_PROXY_HOST']
DB_NAME = os.environ['DB_NAME']

# Create connection outside handler (connection reuse)
try:
    conn = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        passwd=DB_PASS,
        db=DB_NAME,
        connect_timeout=5
    )
    logger.info("SUCCESS: Connected to RDS Proxy")
except pymysql.MySQLError as e:
    logger.error("ERROR: Could not connect to MySQL")
    logger.error(e)
    conn = None


def lambda_handler(event, context):
    if conn is None:
        return "Database connection not initialized"

    try:
        message = event['Records'][0]['body']
        data = json.loads(message)

        cust_id = data['CustID']
        name = data['Name']

        item_count = 0

        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS Customer (
                    CustID INT NOT NULL,
                    Name VARCHAR(255) NOT NULL,
                    PRIMARY KEY (CustID)
                )
            """)

            cur.execute(
                "INSERT INTO Customer (CustID, Name) VALUES (%s, %s)",
                (cust_id, name)
            )

            conn.commit()

            cur.execute("SELECT * FROM Customer")

            logger.info("Current records in DB:")
            for row in cur:
                item_count += 1
                logger.info(row)

        return f"Added {item_count} items to RDS"

    except Exception as e:
        logger.error("Error processing event")
        logger.error(e)
        return str(e)