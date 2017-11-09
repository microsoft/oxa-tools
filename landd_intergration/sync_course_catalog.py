"""

Course catalolg syncronization between OXA and  L&D

"""

import logging
import landd_integration
import click
import click_log

#pylint: disable=line-too-long


logging.basicConfig(filename='course_catalog.log', format='%(asctime)s' '%(message)s', level=logging.DEBUG)
LOG = logging.getLogger(__name__)
HANDLER = logging.handlers.TimedRotatingFileHandler('course_consumption.log', when="d", interval=1, backupCount=10)
LOG.addHandler(HANDLER)


@click.command()
@click.option(
    '--edx-course-catalog-url',
    default='https://lms-lexoxabvtc99-tm.trafficmanager.net/api/courses/v1/courses/',
    help='Course Catalog API url from OpenEdx'
)
@click.option(
    '--key-vault-url',
    default='https://manikeyvault3.vault.azure.net',
    help='Azure key vault url for secrets'
)
@click.option(
    '--landd-catalog-url',
    default='https://ldserviceuat.microsoft.com/Catalog/16/course',
    help='Course Catalog POST API url for L&D'
)
@click.option(
    '--source-system-id',
    type=click.IntRange(0, 100),
    default=16,
    help='source system id provided by L&D'
)
@click_log.simple_verbosity_option(default='INFO')
#@click_log.init()
def sync_course_catalog(edx_course_catalog_url, key_vault_url, landd_catalog_url, source_system_id):
    """
    1) GET access token from Azure tenant using MSI
    2) GET secrets from Azure keyvault using the access token
    3) GET the Course catalog data from OpenEdx using the secrets obtined from Azure key vault
    4) Map and process the OpenEdx course catalog data with L&D Catalog_UpdateMultipleCatalogAsync API request body
    5) POST the mapped data to L&D Catalog_UpdateMultipleCatalogAsync API

    """
    # initialize the key variables
    catalog_service = landd_integration.LdIntegration(logger=LOG)

    # get secrets from Azure Key Vault
    edx_api_key = catalog_service.get_key_vault_secret(catalog_service.get_access_token(), key_vault_url, 'edx-api-key')
    edx_access_token = catalog_service.get_key_vault_secret(catalog_service.get_access_token(), key_vault_url, 'edx-access-token')
    landd_authorityhosturl = catalog_service.get_key_vault_secret(catalog_service.get_access_token(), key_vault_url, 'landd-authorityhosturl')
    landd_clientid = catalog_service.get_key_vault_secret(catalog_service.get_access_token(), key_vault_url, 'landd-clientid')
    landd_clientsecret = catalog_service.get_key_vault_secret(catalog_service.get_access_token(), key_vault_url, 'landd-clientsecret')
    landd_resource = catalog_service.get_key_vault_secret(catalog_service.get_access_token(), key_vault_url, 'landd-resource')
    landd_tenant = catalog_service.get_key_vault_secret(catalog_service.get_access_token(), key_vault_url, 'landd-tenant')
    landd_subscription_key = catalog_service.get_key_vault_secret(catalog_service.get_access_token(), key_vault_url, 'landd-subscription-key')

    # construct headers using key vault secrets
    edx_headers = dict(Authorization='Bearer' + ' ' + edx_access_token, X_API_KEY=edx_api_key)

    headers = {
        'Content-Type': 'application/json',
        'Ocp-Apim-Subscription-Key': landd_subscription_key,
        'Authorization': catalog_service.get_access_token_ld(
            landd_authorityhosturl,
            landd_tenant,
            landd_resource,
            landd_clientid,
            landd_clientsecret
            )
        }

    catalog_data = catalog_service.get_course_catalog_data(edx_course_catalog_url, edx_headers)
    catalog_service.post_data_ld(landd_catalog_url, headers, catalog_service.catalog_data_mapping(source_system_id, catalog_data))

if __name__ == "__main__":
    sync_course_catalog()  # pylint: disable=no-value-for-parameter
