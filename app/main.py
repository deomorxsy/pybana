from pyspark import SparkConf, SparkContext

def main():
    conf = SparkConf().setAppName("AirflowRDDGenerator").setMaster("local[*]")
    sc = SparkContext(conf=conf)

    # create data sample as a list
    data = ["Apache Airflow", "k8s", "spark rdd", "data processing"]

    # create RDD from list
    rdd = sc.parallelize(data)

    # transform RDD to uppercase
    trans_rdd = rdd.map(lambda x: x.upper())

    # collect and print results
    result = transformed_rdd.collect()
    print("Transformed RDD data:")
    for line in result:
        print(line)

    sc.stop()

if __name__ == "__main__":
    main()
