# Databricks notebook source
spark

# COMMAND ----------

storage_account = "depiecommds"
application_id = "<Application_ID>"
directory_id = "<Directory_ID>"

spark.conf.set(f"fs.azure.account.auth.type.{storage_account}.dfs.core.windows.net", "OAuth")
spark.conf.set(f"fs.azure.account.oauth.provider.type.{storage_account}.dfs.core.windows.net", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set(f"fs.azure.account.oauth2.client.id.{storage_account}.dfs.core.windows.net", application_id)
spark.conf.set(f"fs.azure.account.oauth2.client.secret.{storage_account}.dfs.core.windows.net", "<YOUR_AZURE_CLIENT_SECRET>")
spark.conf.set(f"fs.azure.account.oauth2.client.endpoint.{storage_account}.dfs.core.windows.net", f"https://login.microsoftonline.com/{directory_id}/oauth2/token")

# COMMAND ----------

df = spark.read.options(header='true', inferSchema='true').csv("abfss://ecommdata@depiecommds.dfs.core.windows.net/bronze/olist_customers_dataset.csv")
display(df)

# COMMAND ----------

base_path = "abfss://ecommdata@depiecommds.dfs.core.windows.net/bronze/"
geolocation_path = "olist_geolocation_dataset.csv"
order_items_path = "olist_order_items_dataset.csv"
order_payment_path = "olist_order_payments_dataset.csv"
order_reviews_path = "olist_order_reviews_dataset.csv"
orders_path = "olist_orders_dataset.csv"
products_path = "olist_products_dataset.csv"
sellers_path = "olist_sellers_dataset.csv"
product_category_path = "product_category_name_translation.csv"
customers_path = "olist_customers_dataset.csv"

geolocation_df = spark.read.format("csv").option("header", "true").load(base_path + geolocation_path)
order_items_df = spark.read.format("csv").option("header", "true").load(base_path + order_items_path)
order_payment_df = spark.read.format("csv").option("header", "true").load(base_path + order_payment_path)
order_reviews_df = spark.read.format("csv").option("header", "true").load(base_path + order_reviews_path)
orders_df = spark.read.format("csv").option("header", "true").load(base_path + orders_path)
products_df = spark.read.format("csv").option("header", "true").load(base_path + products_path)
sellers_df = spark.read.format("csv").option("header", "true").load(base_path + sellers_path)
product_category_df = spark.read.format("csv").option("header", "true").load(base_path + product_category_path)
customers_df = spark.read.format("csv").option("header", "true").load(base_path + customers_path)

# COMMAND ----------

from pyspark.sql.functions import col, datediff, when, expr



# ==========================================
# 2. SILVER LAYER: Build Dimensions
# ==========================================

dim_customers = customers_df.select(
    "customer_id", "customer_unique_id", "customer_city", "customer_state"
).dropDuplicates(["customer_id"]).dropna(subset=["customer_id"])

dim_products = products_df.fillna({"product_category_name": "Unknown"}).join(
    product_category_df, on="product_category_name", how="left"
).select(
    "product_id", 
    col("product_category_name_english").alias("category_name"),
    expr("try_cast(product_weight_g as float)").alias("product_weight_g")
).dropDuplicates(["product_id"])

dim_sellers = sellers_df.select(
    "seller_id", "seller_city", "seller_state"
).dropDuplicates(["seller_id"])

dim_location = geolocation_df.select(
    col("geolocation_zip_code_prefix").alias("zip_code"),
    expr("try_cast(geolocation_lat as float)").alias("lat"),
    expr("try_cast(geolocation_lng as float)").alias("lng"),
    col("geolocation_city").alias("city"),
    col("geolocation_state").alias("state")
).dropna(subset=["lat", "lng"]).dropDuplicates(["zip_code"])


# ==========================================
# 3. SILVER LAYER: Build Facts (FIXED TIMESTAMPS)
# ==========================================

# FACT: Sales (Using try_cast for all dates)
fact_sales = orders_df.join(order_items_df, on="order_id", how="inner").select(
    "order_id", 
    "customer_id", 
    "product_id", 
    "seller_id", 
    expr("try_cast(price as float)").alias("price"), 
    expr("try_cast(freight_value as float)").alias("freight_value"), 
    "order_purchase_timestamp",
    "order_estimated_delivery_date",
    "order_delivered_customer_date"
).dropna(subset=["order_id", "customer_id", "product_id", "price"]) \
 .withColumn("order_date", expr("try_cast(order_purchase_timestamp as timestamp)")) \
 .withColumn("estimated_delivery", expr("try_cast(order_estimated_delivery_date as timestamp)")) \
 .withColumn("actual_delivery", expr("try_cast(order_delivered_customer_date as timestamp)")) \
 .withColumn(
     "delivery_variance_days", 
     datediff(col("actual_delivery"), col("estimated_delivery"))
 ) \
 .withColumn(
     "is_delayed", 
     when(col("delivery_variance_days") > 0, True).otherwise(False)
 ) \
 .drop("order_purchase_timestamp", "order_estimated_delivery_date", "order_delivered_customer_date")

# FACT: Payments
fact_payments = order_payment_df.select(
    "order_id", 
    expr("try_cast(payment_sequential as int)").alias("payment_sequential"), 
    "payment_type", 
    expr("try_cast(payment_installments as int)").alias("payment_installments"), 
    expr("try_cast(payment_value as float)").alias("payment_value")
).dropna(subset=["order_id", "payment_value"])

# FACT: Reviews (Using try_cast for the date to fix the Portuguese comment error)
fact_reviews = order_reviews_df.select(
    "review_id", "order_id", 
    expr("try_cast(review_score as int)").alias("review_score"), 
    "review_creation_date"
).dropDuplicates(["review_id", "order_id"]).dropna(subset=["order_id"]) \
 .withColumn("review_date", expr("try_cast(review_creation_date as timestamp)")) \
 .drop("review_creation_date")


# ==========================================
# 4. WRITE TO ADLS GEN2 (As Parquet)
# ==========================================
silver_base_path = "abfss://ecommdata@depiecommds.dfs.core.windows.net/silver/"

def write_to_silver_parquet(df, table_name):
    df.write \
      .format("parquet") \
      .mode("overwrite") \
      .save(silver_base_path + table_name)

write_to_silver_parquet(dim_customers, "dim_customers")
write_to_silver_parquet(dim_products, "dim_products")
write_to_silver_parquet(dim_sellers, "dim_sellers")
write_to_silver_parquet(dim_location, "dim_locations")
write_to_silver_parquet(fact_sales, "fact_sales")
write_to_silver_parquet(fact_payments, "fact_payments")
write_to_silver_parquet(fact_reviews, "fact_reviews")

print("Pipeline executed! Malformed rows and stray Portuguese comments skipped safely.")

# COMMAND ----------

