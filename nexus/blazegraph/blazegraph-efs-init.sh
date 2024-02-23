# Blazegraph EFS commands - only the fs id needs to be replaced / parameterised over
sudo mkdir efs-blazegraph
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0e3825287bc361926.efs.us-east-1.amazonaws.com:/ efs-blazegraph
cd efs-blazegraph
sudo mkdir blazegraph-log4j-dir
sudo mkdir blazegraph-data-dir
sudo chmod 777 ./blazegraph-log4j-dir
sudo chmod 777 ./blazegraph-data-dir

cat >> ./blazegraph-log4j-dir/log4j.properties <<EOL
    log4j.rootLogger=INFO, stdout

    # Direct log messages to stdout
    log4j.appender.stdout=org.apache.log4j.ConsoleAppender
    log4j.appender.stdout.Target=System.out
    log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
    log4j.appender.stdout.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n
EOL
