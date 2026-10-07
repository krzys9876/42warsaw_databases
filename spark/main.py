from pyspark.sql import SparkSession
from pyspark.sql.functions import replace, lit, col

def main():
    builder = SparkSession.builder
    builder.master("local[2]")
    builder.appName("test")
    spark = builder.getOrCreate()

    print(f"Spark version: {spark.version}")

    csv_options = {"header": "true", "dateFormat": "yyyy-MM-dd", "timestampFormat": "yyyy-MM-dd HH:mm:ss", "delimiter": ";"}

    df = spark.read.options(**csv_options).format("CSV").load("./data_csv.csv")
    df.printSchema()
    df.show(5)

    # Spark native approach - no SQL involved
    # Note how we reference calculated columns
    df2 = (df
           .withColumn("value_percent_txt", replace(df.value_percent, lit(","), lit(".")))
           .drop("value_percent")
           .withColumn("value_percent", col("value_percent_txt").cast("double"))
           .drop("value_percent_txt")
           .filter(col("value_percent") < 50.0))
    df2.printSchema()
    df2.show(5)

    # Spark SQL approach - use classic SQL (Spark's own dialect)
    # Note that we CAN reference calculated columns in SELECT (value_percent uses value_percent_txt_2)
    # but we CAN'T do the same in WHERE as WHERE is evaluated before SELECT
    df.createOrReplaceTempView("source_df")
    df3 = spark.sql("""
        with src as (
            select 
                ID, name, description, value_percent as value_percent_txt, 
                replace(value_percent, ',', '.') as value_percent_txt_2,
                value_percent_txt_2::double as value_percent
            from source_df
        )
        select ID, name, description, value_percent
        from src
        where value_percent < 50.0 
        """)
    df3.printSchema()
    df3.show(5)

    spark.stop()


if __name__ == '__main__':
    main()
