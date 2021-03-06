Next Release (TBD)
------------------

* Upgrading - Gems - Now publishing three gems:

  * `aws-sdk-core`
  * `aws-sdk-resources`
  * `aws-sdk`

  You can now `gem install aws-sdk --pre` to pull in the preview release
  of version 2 of the AWS SDK for Ruby. If you wish to use v1 and v2 in the
  same applicaiton, you should change your dependency on v1 of `aws-sdk` to
  the `aws-sdk-v1` gem.

* Feature - Resources - Merged in resources branch. You can now use 
  resource-oriented interfaces with `Aws::S3`, `Aws::EC2`, `Aws::SQS`,
  `Aws::SNS`, `Aws::Glacier`,
  and `Aws::IAM`.

* Feature - New Gems - Organized the repository into three gems, `aws-sdk`,
  `aws-sdk-resources`, and `aws-sdk-core`. Moved library and test files
  each into their respective gem directories.

* Issue - Error Class Names - Resolved an issue that could raise a
  `NameError`, "wrong constant name" at runtime in response to a service
  error. Fixes #97.

* Issue - `Aws::CloudSearchDomain::Client` - Resolved an issue that would cause
  the `Aws::CloudSearchDomain::Client` constructor to raise an error when
  `Aws.config[:region]` is set. Fixes #103.

* Issue - Shared Credentials - Resolved an issue where an error was raised
  if the shared AWS credentials file is present and is empty or missing the
  default profile. Fixes #104.

2.0.0.rc15 (2014-08-14)
-----------------------

* Feature - `Aws::S3::Client` - Enabling url-encoding of Amazon S3 keys by default.
  Keys are decoded before response data is returned. See [#95](https://github.com/aws/aws-sdk-core-ruby/issues/95).

* Feature - `Aws::ElasticLoadBalancing::Client` - Added support for the new tagging
  operations.

* Feature - `Aws::CloudSearch::Client` - Will now sign requests when credentials
  are provided. You can continue making unauthenticated requests if you do not
  configure credentials to the client.

* Feature - Coverage - Now generating coverage reports during Travis builds
  and reporting via Coveralls.io.

* Upgrading - `Aws::DynamoDB::Client` - Added a plugin that simplifies working
  with DynamoDB attribute values. Enabled by default, to restore default
  behavior, use `:simple_attributes => false`.

* Issue - Documentation - Now loading API files with UTF-8 encoding.
  See [#92](https://github.com/aws/aws-sdk-core-ruby/issues/92).

2.0.0.rc14 (2014-08-05)
-----------------------

* Upgrading - Client Classes - Versioned client classes removed, e.g.
  `Aws::S3::Client::V20060301.new` is now `Aws::S3::Client.new` The
  `:api_version` constructor option is no longer accepted.

* Upgrading - `Aws` Module - Helper methods on `Aws` for client classes
  deprecated; For example, calling `Aws.s3` will generate a deprecation
  warning. Use `Aws::S3::Client.new` instead. Helpers will be removed as
  of v2.0.0 final.

* Upgrading - Config - When configuring an `:endpoint`, you must now specify
  the HTTP scheme, e.g. "http://localhost:3000", instead of "localhost:3000".

2.0.0.rc1 - 2.0.0.rc13
----------------------

* No changelog entries.
