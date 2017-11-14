# OpenEdx data intergatoin with L&D Services

This Following intergatoin includes the transfer of course details and user's consumption data from OpenEdx to L&D services.
1. ALL the Meta Data of Courses created by staff in Openedx will be sent to L&D servies which shows up on Infopedia site.
2. User's entered in Infopedia courses will be redirected to OpenEdx site based on the Course URL
3. After making some Activty, All User's consumption data will be sent back to L&D site which shows up in Infopedia.

Here are the API's used: 

**OpenEdx:**    

  - Course catalog API         -- GET /api/courses/v1/courses/
  - Bulk Gradees API           -- GET /api/grades/v1/user_grades/?username=all


  
**L&D servies:**

  - Catalog_UpdateMultipleCatalogAsync                -- POST /Catalog/{sourceSystemId}/course
  - Consumption_SaveMultipleExperienceTrackingAsync   -- POST /Consumption/exptrack

  
  

**Logging**


    All the logs related to course catalog are logged  in `course_catalog.log`
	All the logs related to course consumption are logged in `course_consumption.log`
	By default the LOG files will be stored in seperate files for every 24 hours
	By default logs for the past 10 days are stored

	
	
	
**Time Logging**


    
    Bulk Gradees API acccepts start_data and end_date as parameters:
        start_data:For each Execution of script, time of the API call for Bulk Gradees API is logged in `api_call_time.txt` which will be used as start time for the subsequent run
        end_date:By default end_date will be taken as current date and time

		
		
		


*Usage:* `sync_course_catalog.py` [OPTIONS]

  1. GET access token from Azure tenant using MSI 
  2. GET secrets from Azure keyvault using the access token 
  3. GET the Course catalog data from OpenEdx using the secrets obtined from Azure key vault 
  4. Map and process the OpenEdx course catalog data with L&D Catalog_UpdateMultipleCatalogAsync API request body 
  5. POST the mapped data to L&D Catalog_UpdateMultipleCatalogAsync API

*Options:*

  --edx-course-catalog-url       Course Catalog API url from OpenEdx

  --key-vault-url                Azure key vault url for secrets

  --landd-catalog-url            Course Catalog POST API url for L&D

  --source-system-id             Source system id provided by L&D

  --help                          Show this message and exit.


  
  
*Usage:* `sync_course_consumption.py` [OPTIONS]

  1. GET access token from Azure tenant using MSI
  2. GET secrets from Azure keyvault using the access token 
  3. GET the Course catalog data from OpenEdx using the secrets obtined from Azure key vault 
  4. Map and process the OpenEdx course catalog data with L&D Catalog Consumption API request body
  5. POST the mapped data to L&D Catalog Consumption API

*Options:*

  --edx-course-consumption-url Course Consumption API url from OpenEdx

  --key-vault-url              Azure key vault url for secrets
  
  --landd-consumption-url      Course Consumption POST API url for L&D
  
  --source-system-id           Source system id provided by L&D
  
  -v, --verbosity LVL             Either CRITICAL, ERROR, WARNING, INFO or
                                  DEBUG
  
  --help                          Show this message and exit.

	
 
