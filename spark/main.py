from pyspark.sql import SparkSession
from pyspark.sql.functions import replace, lit, col

def main():
    file_name = "./data_csv.csv"
    max_lines = 5
    csv_options = {"header": "true", "dateFormat": "yyyy-MM-dd", "timestampFormat": "yyyy-MM-dd HH:mm:ss", "delimiter": ";"}

    # Initialize Spark session
    spark = SparkSession.builder.master("local[2]").appName("test").getOrCreate()

    print(f"Spark version: {spark.version}")

    # Source data in CSV format
    print("\n----------------------\nRaw source data from file\n")
    with open(file_name, "r") as f:
        contents = f.readlines()
        for l in contents[:max_lines+1]:
            print(l.strip())

    print("\n----------------------\nRaw source data read by Spark\n")
    df = spark.read.options(**csv_options).format("CSV").load("./data_csv.csv")
    df.printSchema() # NOTE: all data types set to string as we haven't provided any type hints
    df.show(max_lines)

    # Spark native approach - no SQL involved
    # Note how we reference calculated columns
    print("\n----------------------\nProcessing data using Spark native API\n")
    df2 = (df
           .withColumn("ID", df.ID.cast("int"))
           .withColumn("value_percent_txt", replace(df.value_percent, lit(","), lit(".")))
           .drop("value_percent")
           .withColumn("value_percent", col("value_percent_txt").cast("double"))
           .drop("value_percent_txt")
           .filter(col("value_percent") < 50.0)
           .orderBy(col("value_percent").desc()))
    df2.printSchema()
    df2.show(max_lines)

    # Spark SQL approach - use classic SQL (Spark's own dialect)
    # Note that we CAN reference calculated columns in SELECT (value_percent uses value_percent_txt_2)
    # but we CAN'T do the same in WHERE as WHERE is evaluated before SELECT
    print("\n----------------------\nProcessing data using Spark SQL\n")
    df.createOrReplaceTempView("source_df")
    df3 = spark.sql("""
        with src as (
            select 
                ID::int, name, description, value_percent as value_percent_txt, 
                replace(value_percent, ',', '.') as value_percent_txt_2,
                value_percent_txt_2::double as value_percent
            from source_df
        )
        select ID, name, description, value_percent
        from src
        where value_percent < 50.0 
        order by value_percent desc
        """)
    df3.printSchema()
    df3.show(max_lines)

    spark.stop()


if __name__ == '__main__':
    main()
