# Domain 3: Design High-Performing Architectures (24%)

## [Amazon EBS & Amazon EFS](https://docs.aws.amazon.com/ebs/)
- [ ] Select block volume classes (`gp3`, `io2 Block Express`) matching targeted IOPS/throughput limits.
- [ ] Implement EBS Multi-Attach patterns to support clustered compute operations.
- [ ] Deploy POSIX-compliant file systems using EFS with appropriate Provisioned/Elastic throughput and General Purpose/Max I/O performance profiles.

## [Amazon S3 (Simple Storage Service)](https://docs.aws.amazon.com/s3/)
- [ ] Optimize high-throughput key-prefix data request rates on S3 buckets.
- [ ] Accelerate file uploads by configuring Multipart Upload mechanics.
- [ ] Streamline low-latency content distribution by proxying S3 origins behind [Amazon CloudFront](https://docs.aws.amazon.com/cloudfront/).

## [Amazon RDS & Amazon Aurora](https://docs.aws.amazon.com/rds/)
- [ ] Mitigate read-intensive workload constraints by scaling out asynchronous Read Replicas.
- [ ] Implement [Amazon RDS Proxy](https://docs.aws.amazon.com/rds/proxy/) pools to optimize application connection scaling limits.
- [ ] Design ultra-low-latency distributed configurations using Aurora Global Databases.

## [Amazon DynamoDB & Amazon ElastiCache](https://docs.aws.amazon.com/amazondynamodb/)
- [ ] Structuralize schema data distribution using optimal Partition Keys (PK) and Sort Keys (SK).
- [ ] Manage throughput constraints using Provisioned (RCU/WCU) vs On-Demand capacity modes.
- [ ] Achieve sub-millisecond data read returns by fronting tables with DynamoDB Accelerator (DAX).
- [ ] Integrate caching strategies via ElastiCache (Redis OSS vs Memcached) to minimize primary database stress.

## [Amazon CloudFront & AWS Global Accelerator](https://docs.aws.amazon.com/cloudfront/)
- [ ] Cache dynamic and static web content at global edge locations using optimized Cache Behaviors and TTLs.
- [ ] Optimize network ingress bottlenecks over the AWS global network using Anycast IPs on Global Accelerator.

## [Amazon Kinesis](https://docs.aws.amazon.com/kinesis/)
- [ ] Architect high-volume data streaming pipelines using Kinesis Data Streams.
- [ ] Calculate ingestion partition limits through active shard tuning.
- [ ] Stream real-time analytical ingest to storage sinks using Kinesis Data Firehose.

## [AWS Analytical Processing & Big Data](https://docs.aws.amazon.com/athena/)
- [ ] Perform serverless, ad-hoc queries against unstructured S3 data pools using Amazon Athena.
- [ ] Provision big-data cluster frameworks utilizing [Amazon EMR](https://docs.aws.amazon.com/emr/).
- [ ] Build automated ETL data transform operations across schemas using [AWS Glue](https://docs.aws.amazon.com/glue/).
- [ ] Deploy petabyte-scale data warehouse solutions with [Amazon Redshift](https://docs.aws.amazon.com/redshift/).
