# ET to CCD Exporter

[![Build Status](https://dev.azure.com/HMCTS-PET/pet-azure-infrastructure/_apis/build/status/et/et-ccd-export?branchName=develop)](https://dev.azure.com/HMCTS-PET/pet-azure-infrastructure/_build/latest?definitionId=23&branchName=develop)

This application is to be used alongside the Employment Tribunals API service.  It shares the same redis connection
for sidekiq.

It works by monitoring a queue called external_system_ccd - whenever a worker called ExternalSystemExportWorker is
queued, it will be executed by this application and the data sent to CCD.

## Configuration

The application must be configured to use the same redis details as the API service.  See the environment variables below

### Environment Variables

1. The redis config can be configured using the following to allow just the port to be overriden (useful for local development)
   REDIS_HOST (defaults to localhost)
   REDIS_PORT (defaults to 6379)
   REDIS_DATABASE (defaults to 1)
   STORAGE_REDIS_DATABASE (defaults to 2)

   You can change any of these individually or you can ignore these by setting the full
   REDIS_URL in the traditional way - such as :-

   ```

   REDIS_URL=redis://localhost:6379/12

   ```

   If your redis server needs a password, it must be specified using

   ```
   REDIS_PASSWORD=<your password>

   ```

2. Generating interim 'ethosCaseReference' field in the data to CCD
   
   During a transition period whilst CCD is being developed, it was required to generate an ethosCaseReference field.
   In local environments and also when using fake ccd it is best for this to be disabled (so ET3 tests can use a properly formatted
   case reference)
   
   To disable - set this
   
   ```
   GENERATE_ETHOS_CASE_REFERENCE=false
   ``` 
   
   If this is omitted or set to 'true' - the functionality will be enabled.
   
3. Logging levels can be changed using the following (note that
   this is not a rails app, but I have kept the same naming
   convention as a rails app)
   
   ```
   RAILS_LOG_LEVEL=debug
   ```
   
   values are debug (noisiest) , info, warn, error and fatal (quietist)

4. Disabling 'sidekiq_alive' (provides a http server to sense
   if sidekiq is running or not - used in deployment) can be done
   as follows :-
   
   ```
   DISABLE_SIDEKIQ_ALIVE=true
   ```
   
   To re enable you must completely remove this env var
   
5. Controlling sidekiq threads
   Increasing the number of threads available to sidekiq is a good and a bad thing.
   It is good because more cases will go to CCD in parallel, but it is bad because
   it might overload CCD.
   
   So, to control the threads (defaults to 20) - change this env var
   
   ```
   RAILS_MAX_THREADS=<value>
   ```
   
6. Connecting to sentry is easy. Just set :-

    ```
    RAVEN_DSN=<your sentry dsn>
    ```
    
    and if your sentry doesnt have a valid SSL cert do
    
    ```
    RAVEN_SSL_VERIFICATION=false
    ```
    
7. Configuration for CCD

    There are 3 base urls which have defaults to allow the system to work alongside ccd-docker.
    These will need configuring in real environments to point to a real CCD
    
    ```
    CCD_AUTH_BASE_URL=<service-auth-provider-api base URL>
    CCD_IDAM_BASE_URL=<idam-api base URL>
    CCD_DATA_STORE_BASE_URL=<ccd-data-store-api base URL>
    CCD_DOCUMENT_STORE_BASE_URL=<ccd-document-store-api base URL>
    CCD_DOCUMENT_STORE_REWRITE=<rewrite spec or false - see below>

    ```
    

    If any of the above urls use SSL and do not have valid certificates, switch off validation using

    ```
    CCD_SSL_VERIFICATION=false

    ```
    
    Also, the 'jurisdiction id' (jid) can be changed from its default (EMPLOYMENT) as follows
    
    ```
    CCD_JURISDICTION_ID=<jurisdiction id>
    ```
    
    The 'microservice' that is used to get a token in idam is 'ccd_gw' as standard.  To change
    this do :-
    
    ```
    CCD_MICROSERVICE_ID=<microservice>
    ```
    
    and
    
    ```
    CCD_MICROSERVICE_SECRET=<microservice-secret>
    ```

    When a case is created, it is owned by a particular idam user.  The username
    and password is required below:

    ```
    CCD_SIDAM_USERNAME=<the username of the idam user to create cases for>
    CCD_SIDAM_PASSWORD=<the password for the above>
    ```
    
    The CCD client uses a connection pool which is pre logged in.  This is for efficiency
    To control the size of this pool, use the following
    
    ```
    CCD_CLIENT_POOL_SIZE = <size> (where size should not be less than the concurrency in sidekiq else workers will become blocked)
    CCD_CLIENT_POOL_TIMEOUT = <timeout seconds> Set this to the max amount of time the code should wait for a client from the pool to become available
    ```
    
    The CCD_DOCUMENT_STORE_REWRITE variable should either contain 'false' if
    the URL's that come back from uploading a document should be used as
    is OR a specification to define that the urls should be remapped because of 
    docker port forwarding for example.
    
    So, if you are using docker, it should be set as follows
    
    ```
    CCD_DOCUMENT_STORE_REWRITE=localhost:4506:dm-store:8080
    ```
    
    Which means 'If localhost:4506' is returned, re map it to dm-store:8080
    
    Without this, the CCD services that want to access this data from inside docker,
    will not be able to.

8. CCD Document Store - Disallowed types

At the time of writing, ccd document store will not store RTF and CSV files.  There is a change going through to the whitelist
but to prevent cases from going through as a result of any errors raised by this - you can control which file types are disallowed
using the following

CCD_DOCUMENT_STORE_DISALLOW_FILE_EXTENSIONS=.csv,.rtf

which is just a comma separated list of file extensions to disallow (including the dot)

## Running

First, clone this repository into et-ccd-export

Then

```

cd et-ccd-export

./bin/setup

```

then

```

./bin/sidekiq --config config/sidekiq.yml



```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
