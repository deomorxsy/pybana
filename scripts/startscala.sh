 #!/bin/sh
# create src scala
mkdir -p "./src/main/scala/util/"

if ! [ -f "./src/main/scala/SparkApp.scala" ]; then
    if ! touch "./src/main/scala/SparkApp.scala"; then
        echo "|> [ERROR]: it was not possible to create SparkApp. Exiting now..."
        return 1
    fi
        echo "|> [PASS]: successfully created SparkApp. Proceeding..."
fi

if ! [ -f "./src/main/scala/util/Executor.scala" ]; then
    if ! touch "./src/main/scala/util/Executor.scala"; then
        echo "|> [ERROR]: it was not possible to create Executor. Exiting now..."
        return 1
    fi
        echo "|> [PASS]: successfully created Executor. Proceeding..."
fi
# create test scala
mkdir -p "./test/scala/"
if ! [ -f "./test/scala/ExecutorTest.scala" ]; then

    if ! touch "./test/scala/ExecutorTest.scala"; then
        echo "|> [ERROR]: it was not possible to create ExecutorTest. Exiting now..."
        return 1
    fi
        echo "|> [PASS]: successfully created ExecutorTest. Proceeding..."

fi

