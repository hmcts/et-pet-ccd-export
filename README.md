# ET to CCD Exporter

[![Build Status](https://dev.azure.com/HMCTS-PET/pet-azure-infrastructure/_apis/build/status/et/et-ccd-export?branchName=develop)](https://dev.azure.com/HMCTS-PET/pet-azure-infrastructure/_build/latest?definitionId=23&branchName=develop)

This application is now to be used inside the Employment Tribunals API service.  It no longer uses redis or sidekiq but
'good jobs' using the database instead.

The code is in the process of being migrated to the API instead of having its own repository


6. Configuration for CCD

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
    CCD_CLIENT_POOL_SIZE = <size> (where size should not be less than the concurrency in active job else workers will become blocked)
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

6.1 'External System' config entries in admin

  #### multiples_max_claimant_count

  This allows the office to define the maximum amount of
  claimants for a multiple.


7. CCD Document Store - Disallowed types

At the time of writing, ccd document store will not store RTF and CSV files.  There is a change going through to the whitelist
but to prevent cases from going through as a result of any errors raised by this - you can control which file types are disallowed
using the following

CCD_DOCUMENT_STORE_DISALLOW_FILE_EXTENSIONS=.csv,.rtf

which is just a comma separated list of file extensions to disallow (including the dot)

## Running

This is no longer able to run standalone


```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
