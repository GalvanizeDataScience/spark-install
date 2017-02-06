#!/bin/bash

echo "DOWNLOADING SPARK"

# Specify your shell config file
# Aliases will be appended to this file
SHELL_PROFILE="$HOME/.bash_profile"

# Specify the URL to download Spark from
SPARK_URL=http://apache.mirrors.tds.net/spark/spark-2.1.0/spark-2.1.0-bin-hadoop2.7.tgz

# The Spark folder name should be the same as the name of the file being downloaded as specified in the SPARK_URL
SPARK_FOLDER_NAME=spark-2.1.0-bin-hadoop2.7.tgz

# Find the proper md5 hash from the Apache site
SPARK_MD5=50e73f255f9bde50789ad5bd657c7a71

# Print Disclaimer prior to running script
echo "DISCLAIMER: This is an automated script for installing Spark but you should feel responsible for what you're doing!"
echo "This script will install Spark to your home directory, modify your PATH, and add environment variables to your SHELL config file"
read -r -p "Proceed? [y/N] " response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "Aborting..."
    exit 1
fi

# Verify that $SHELL_PROFILE is pointing to the proper file
read -r -p "Is $SHELL_PROFILE your shell profile? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "All relevent aliases will be added to this file"
else
    echo "Please alter the spark-install.sh script to specify the correct file"
    exit 1
fi

# Create scripts folder for storing jupyspark.sh and localsparksubmit.sh
read -r -p "Would you like to create a scripts folder in your Home directory? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    if [[ ! -d $HOME/scripts ]]
    then
        mkdir $HOME/scripts
        echo "export PATH=\$PATH:$HOME/scripts" >> $SHELL_PROFILE
    else
        echo "scripts folder already exists! Verify this folder has been added to your PATH"
    fi
else
    if [[ ! -d $HOME/scripts ]]
    then
        echo "Installing without installing jupyspark.sh and localsparksubmit.sh"
    fi
fi

if [[ -d $HOME/scripts ]];
then
    # Create jupyspark.sh script in your scripts folder
    read -r -p "Would you like to create the jupyspark.sh script for launching a local jupyter spark server? [y/N] " response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "#!/bin/bash
        export PYSPARK_DRIVER_PYTHON=jupyter
        export PYSPARK_DRIVER_PYTHON_OPTS=\"notebook --NotebookApp.open_browser=True --NotebookApp.ip='localhost' --NotebookApp.port=8888\"

        \${SPARK_HOME}/bin/pyspark \
        --master local[4] \
        --executor-memory 1G \
        --driver-memory 1G \
        --conf spark.sql.warehouse.dir=\"file:///tmp/spark-warehouse\" \
        --packages com.databricks:spark-csv_2.11:1.5.0 \
        --packages com.amazonaws:aws-java-sdk-pom:1.10.34 \
        --packages org.apache.hadoop:hadoop-aws:2.7.3" > $HOME/scripts/jupyspark.sh

        chmod +x $HOME/scripts/jupyspark.sh
    fi

    # Create localsparksubmit.sh script in your scripts folder
    read -r -p "Would you like to create the localsparksubmit.sh script for submittiing local python scripts through spark-submit? [y/N] " response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "#!/bin/bash
        \${SPARK_HOME}/bin/spark-submit \
        --master local[4] \
        --executor-memory 1G \
        --driver-memory 1G \
        --conf spark.sql.warehouse.dir=\"file:///tmp/spark-warehouse\" \
        --packages com.databricks:spark-csv_2.11:1.5.0 \
        --packages com.amazonaws:aws-java-sdk-pom:1.10.34 \
        --packages org.apache.hadoop:hadoop-aws:2.7.3 \
        \$1" > $HOME/scripts/localsparksubmit.sh

        chmod +x $HOME/scripts/localsparksubmit.sh
    fi
fi

# Check to see if JDK is installed
javac -version 2> /dev/null
if [ ! $? -eq 0 ]
then
    # Install JDK
    if [[ $(uname -s) = "Darwin" ]]
    then
        echo "Downloading JDK..."
        brew install Caskroom/cask/java
    elif [[ $(uname -s) = "Linux" ]]
    then
        echo "Downloading JDK..."
        sudo add-apt-repository ppa:webupd8team/java
        sudo apt-get update
        sudo apt-get install oracle-java8-installer
    fi
fi

SUCCESSFUL_SPARK_INSTALL=0
SPARK_INSTALL_TRY=0

if [[ $(uname -s) = "Darwin" ]]
then
    echo "\n\tDetected Mac OS X as the Operating System\n"

    while [ $SUCCESSFUL_SPARK_INSTALL -eq 0 ]
    do
        curl $SPARK_URL > $HOME/$SPARK_FOLDER_NAME
        # Check MD5 Hash
        if [[ $(openssl md5 $HOME/$SPARK_FOLDER_NAME | sed -e "s/^.* //") == "$SPARK_MD5" ]]
        then
            # Unzip
            tar -xzf $HOME/$SPARK_FOLDER_NAME -C $HOME
            # Remove the compressed file
            rm $HOME/$SPARK_FOLDER_NAME
            # Install py4j
            $HOME/anaconda2/bin/pip install py4j
            SUCCESSFUL_SPARK_INSTALL=1
        else
            echo 'ERROR: Spark MD5 Hash does not match'
            echo "$(openssl md5 $HOME/$SPARK_FOLDER_NAME | sed -e "s/^.* //") != $SPARK_MD5"
            if [ $SPARK_INSTALL_TRY -lt 3 ]
            then
                echo -e '\nTrying Spark Install Again...\n'
                SPARK_INSTALL_TRY=$[$SPARK_INSTALL_TRY+1]
                echo $SPARK_INSTALL_TRY
            else
                echo -e '\nSPARK INSTALL FAILED\n'
                echo -e 'Check the MD5 Hash and run again'
                exit 1
            fi
        fi
    done
elif [[ $(uname -s) = "Linux" ]]
then
    echo -e "\n\tDetected Linux as the Operating System\n"

    while [ $SUCCESSFUL_SPARK_INSTALL -eq 0 ]
    do
        curl $SPARK_URL > $HOME/$SPARK_FOLDER_NAME
        # Check MD5 Hash
        if [[ $(md5sum $HOME/$SPARK_FOLDER_NAME | sed -e "s/ .*$//") == "$SPARK_MD5" ]]
        then
            # Unzip
            tar -xzf $HOME/$SPARK_FOLDER_NAME -C $HOME
            # Remove the compressed file
            rm $HOME/$SPARK_FOLDER_NAME
            # Install py4j
            $HOME/anaconda2/bin/pip install py4j
            SUCCESSFUL_SPARK_INSTALL=1
        else
            echo 'ERROR: Spark MD5 Hash does not match'
            echo "$(md5sum $HOME/$SPARK_FOLDER_NAME | sed -e "s/ .*$//") != $SPARK_MD5"
            if [ $SPARK_INSTALL_TRY -lt 3 ]
            then
                echo -e '\nTrying Spark Install Again...\n'
                SPARK_INSTALL_TRY=$[$SPARK_INSTALL_TRY+1]
                echo $SPARK_INSTALL_TRY
            else
                echo -e '\nSPARK INSTALL FAILED\n'
                echo -e 'Check the MD5 Hash and run again'
                exit 1
            fi
        fi
    done
else
    echo "Unable to detect Operating System"
    exit 1
fi

# Remove extension from spark folder name
SPARK_FOLDER_NAME=$(echo $SPARK_FOLDER_NAME | sed -e "s/.tgz$//")

echo "
# Spark variables
export SPARK_HOME=\"$HOME/$SPARK_FOLDER_NAME\"
export PYTHONPATH=\"$HOME/$SPARK_FOLDER_NAME/python/:$PYTHONPATH\"

# Spark 2
export PYSPARK_DRIVER_PYTHON=ipython
alias pyspark=\"$HOME/$SPARK_FOLDER_NAME/bin/pyspark \
    --conf spark.sql.warehouse.dir='file:///tmp/spark-warehouse' \
    --packages com.databricks:spark-csv_2.11:1.5.0 \
    --packages com.amazonaws:aws-java-sdk-pom:1.10.34 \
    --packages org.apache.hadoop:hadoop-aws:2.7.3\"" >> $SHELL_PROFILE

source $SHELL_PROFILE

echo "INSTALL COMPLETE"
echo "Please refer to Step 4 at https://github.com/zipfian/spark-install for testing your installation"
