#!/bin/python3

%load_ext sparkmagic.magics
%manage_spark


%%configure -f
            {
            "name": "remotesparkmagics-sample",
            "executorMemory": "10G",
            "executorCores": 8,
            "numExecutors": 3
            }

# initializes the job
spark


# Sample data
data = [
    ("Alice", 25),
    ("Bob", 30),
    ("Charlie", 35)
]

# Define schema
columns = ["Name", "Age"]

# Create DataFrame
df = spark.createDataFrame(data, columns)

# Show DataFrame
df.show()

print(spark.version())
